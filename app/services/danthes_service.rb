class DanthesService
  def initialize(object)
    @object = object
  end

  def media_channel_id
    return if @object.nil?
    @media_channel_id ||= case @object
                          when ::Message
                            return if @object.task.nil?
                            @object.task.media_channel_id
                          when ::Task
                            @object.media_channel_id
                          end
  end

  def push_to_browser
    push_to_media_channel
  end

  def alert_expiring_waiting_task_to_browser
    ::Danthes.publish_to "/media_channels/#{media_channel_id}/tasks/alertWaitingTaskTimeout", json_for_push_to_browser
  end

  def json_for_push_to_browser
    data = {}
    case @object
    when ::Message
      data.merge!({
        task: task_json_for(Task.find(@object.task_id).decorate),
        message: message_json_for(@object.decorate)
      })
    when ::Task
      @object.include_messages = true
      data[:task] = task_json_for(@object.decorate)
    end
    data
  end

  def is_open
   return if @object.nil?
   case @object
     when ::Message
       return if @object.task.nil?
       @object.task.open_to_all
     when ::Task
       @object.open_to_all
     end
  end

  def publish_to_media_channel(media_channel_id)
    ::Danthes.publish_to "/media_channels/#{media_channel_id}/tasks", json_for_push_to_browser
  end


  def message_json_for(message)
    message_json = ::MessageSerializer.new(message).as_json
    message_json.merge(::ExtendMessageSerializer.new(message).as_json)
  end

  def task_json_for(task)
    return '{}' if task.media_channel.nil? and task.service_channel.nil?
    ::FullTaskSerializer.new(task).as_json
  end

  def publish_task(media_channels)
    media_channels.each do |mc|
      publish_to_media_channel(mc.id)
    end
  end

  def publish_high_priority_task
    company_id = @object.service_channel.company_id
    service_channel_ids = ServiceChannel.where(company_id: company_id).ids

    @object.media_channel.type.constantize.where(service_channel_id: service_channel_ids).pluck(:id).each do |channel_id|
      ::Danthes.publish_to "/media_channels/#{channel_id}/tasks", json_for_push_to_browser
    end
  end

  def publish_medium_priority_task
    channels = @object.media_channel.type.constantize.where(service_channel_id: @object.service_channel_id)
    channels.each do |channel|
      ::Danthes.publish_to "/media_channels/#{channel.id}/tasks", json_for_push_to_browser
    end
  end

  def publish_low_priority_task
    company_id = @object.service_channel.company_id

    low_priorities = Priority.where(priority_value: 1, company_id: company_id).pluck(:tag_id)
    low_priority_tags = ActsAsTaggableOn::Tag.find(low_priorities).map(&:name)

    service_channel_ids = ServiceChannel.where(company_id: company_id).tagged_with(low_priority_tags, any: true).ids

    channels = @object.media_channel.type.constantize.where(service_channel_id: service_channel_ids).ids
    channels <<  @object.media_channel_id

    channels.uniq.each do |channel_id|
      ::Danthes.publish_to "/media_channels/#{channel_id}/tasks", json_for_push_to_browser
    end
  end

  def no_priority_tags
    no_priorities = Priority.where(priority_value: 0).pluck(:tag_id)
    ActsAsTaggableOn::Tag.find(no_priorities).map(&:name)
  end

  def publish_no_priority_task
    service_channel_ids = @object.service_channel.company.service_channels.ids
    channels = @object.media_channel.type.constantize.where(service_channel_id: service_channel_ids).ids

    channels.uniq.each do |channel_id|
      ::Danthes.publish_to "/media_channels/#{channel_id}/tasks", json_for_push_to_browser
    end
  end

  def publish_to_all
    case @object
      when ::Message
        publish_to_media_channel(media_channel_id) if media_channel_id
      when ::Task
        if @object.task_priority == 3
          publish_high_priority_task
        elsif @object.task_priority == 2
          publish_medium_priority_task
        elsif @object.task_priority == 1
          publish_low_priority_task
        else
          publish_no_priority_task
        end
      end
  end

  def check_low_priority
    case @object
      when ::Message
        false
      when ::Task
        @object.skills.count.zero?
      end
  end

  def push_to_media_channel
    if is_open
      publish_to_all
    else
      if check_low_priority
        publish_low_priority_task
      else
        publish_to_media_channel(media_channel_id) if media_channel_id
      end
    end
    # ::Danthes.publish_to "/media_channels/#{media_channel_id}/tasks", json_for_push_to_browser if media_channel_id
  end

end
