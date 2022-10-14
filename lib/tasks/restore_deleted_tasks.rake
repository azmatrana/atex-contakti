#Restores all deleted tasks for a given company and redos the actions that were done to the deleted tasks previously
task :restore_deleted_tasks => :environment do
  company_id = ENV['company_id']
  deleted_task_ids = get_task_versions_for_company(company_id)
  puts "restoring #{deleted_task_ids.length} tasks"
  restore_tasks(deleted_task_ids)
end

#Gets all TaskVersions associated with the deleted task and redos their create and update events
def restore_tasks(deleted_task_ids)
  count = deleted_task_ids.count
  cf = "%#{count.to_s.length}d"

  # Prevent millions of useless worker jobs being created
  Task.skip_callback :commit, :after, :push_task_to_browser
  Message.skip_callback :commit, :after, :push_message_on_queue_on_update
  Message.skip_callback :commit, :after, :push_message_on_queue_on_create
  Message.skip_callback :commit, :after, :push_message_to_browser_on_create
  Message.skip_callback :commit, :after, :push_message_to_browser_on_update

  # Prevent tasks.assigned_at from being updated to current date
  Task.skip_callback :save, :before, :check_assign_changing

  deleted_task_ids.each_with_index do |item_id, i|
    print "Restoring task #{cf % (i+1)}/#{count} id: #{item_id}..."
    versions = TaskVersion.where('event != ? AND item_id = ? AND item_type = ?',"destroy", item_id, "Task").order(:created_at)
    new_id = repeat_version_actions(versions)

    new_task = Task.find(new_id)
    create_message_for_task(new_task) if new_task.messages.empty?

    puts " new id: #{new_id}"
  end
end

#Creates and updates tasks according to the task versions
def repeat_version_actions(versions)
  new_id = nil
  versions.each_with_index do |v, i|
    object_changes = PaperTrail.serializer.load(v.object_changes)
    old_id = v.item_id
    params = extract_params(object_changes)
    case v.event
      when "create"
        new_task = Task.create(params)
        if new_task
          restore_associations(new_task, old_id)
          new_id = new_task.id
        end
      else
        task = Task.find(new_id)
        task.update_attributes(params)
    end
    v.destroy #Remove the task_version in order to now accidentally re-create everything twice
  end
  new_id
end

#Re-associates messages to the new task
def restore_associations(new_task, old_id)
  #Restore messages
  messages = Message.only_deleted.where(:task_id => old_id)
  messages.each do |m|
    m.recover
    m.update_attribute(:task_id, new_task.id)
    puts "Associated message #{m.id.to_s} with task: #{new_task.id.to_s}"
  end
end

#TaskVersion params values are of type [oldval,newval]. We only need the new value. Also delete the id to prevent collisions
def extract_params(changes)
  changes.each{|k,v|changes[k] = v[1]}
  changes.delete(:id)#Should not cause collisions but delete it to be sure
  changes
end

#Gets all task versions that belong to a deleted task of the company in question
def get_task_versions_for_company(company_id)
  company = Company.find(company_id)
  service_channel_ids = company.service_channels.pluck(:id)
  task_version_item_ids = []
  TaskVersion.where(:event => "create").each do |tv|
    if tv.item.nil?
      task_version_attributes = PaperTrail.serializer.load(tv.object_changes)
      task_version_item_ids << tv.item_id if service_channel_ids.include?(task_version_attributes['service_channel_id'][1])
    end
  end
  task_version_item_ids
end

def create_message_for_task(task)
  params = {
      from: '(Unknown)',
      to: '(Unknown)',
      title: '',
      description: '',
      task_id: task.id,
      number: 1,
      channel_type: task.media_channel.channel_type,
      created_at: task.created_at,
      updated_at: task.updated_at,
  }

  type_params = case params[:channel_type]
    when 'call'
      {
          title: "#{I18n.t('user_dashboard.unanswered_call')} #{task.data['caller_name']}",
          description: task.created_at.to_s,
          channel_type: 'call'
      }
    else # Nothing on Task about other types!?
      {}
  end

  ::Message.create!(params.merge(type_params))
end
