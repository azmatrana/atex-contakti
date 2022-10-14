class Ability
  require 'cancan/ability'
  include CanCan::Ability

  def initialize(user)
    @user = user || User.new
    if @user.has_role? :admin
      define_admin_rules
    else
      can :manage, ::User, id: @user.id
      can :read, ::SmsTemplate, company_id: @user.company_id
      can :manage, ::Task
      can :manage, ::MediaChannel
      #define_task_rules
    end
  end

  def define_admin_rules
    [::User, ::Location, ::ServiceChannel, ::Report, ::SmtpSettings, ::ImapSettings, ::SmsTemplate, ::DashboardLayout].each do |klass|
      can [:read, :manage], klass, company_id: @user.company_id
    end
    can :manage, ::Company, id: @user.company_id
  end

  def define_task_rules
    # Owned tasks
    # Only tasks of media channel types allowed to user
    # And only active media channels
    # Can grab task if it in new state
    channel_ids = ::MediaChannel.joins(:service_channel => :users)
                                .where('service_channels.company_id' => @user.company_id)
                                .where(service_channels_users: { user_id: @user.id})
                                .where(type: @user.media_channel_types.map { |c| ::MediaChannel.get_classname_by_channel_type(c) })
                                .where(active: true)
                                .select(:id).to_a

    combined_channel_ids = channel_ids.collect(&:id)

    if @user.service_channel and @user.service_channel.email_media_channel
      combined_channel_ids << @user.service_channel.email_media_channel.id
    end
    combined_channel_ids << 386

    arel_table = Task.arel_table
    open_to_all = arel_table[:state].in(%w(open))
      .and(arel_table[:assigned_to_user_id].eq(nil))
      .and(arel_table[:media_channel_id].in(combined_channel_ids))

    user_skills = @user.user_skills

    all_tasks = Task.eager_load(:skills).where(service_channel_id: @user.company.service_channels.ids)
    task_with_high_priority = all_tasks.select { |rec| rec.custom_task_priority(rec.skills) == 3 && rec.open_to_all == true }
    medium_priority_tasks = all_tasks.select { |task| task.custom_task_priority(task.skills) == 2 && task.open_to_all == true && task.service_channel_agent_ids.include?(@user.id) }
    low_priority_tasks = all_tasks.select { |task| task.custom_task_priority(task.skills).in?([1, 2]) && task.open_to_all == true && task.skills_matched_service_channel_agents(task.skills).present? }
  
    allowed_low_priority_task_ids = []
    disallowed_low_priority_task_ids = []

    low_priority_tasks.select{|task| task.skills_matched_service_channel_agents(task.skills).include?(@user.id) ? allowed_low_priority_task_ids << task.id : disallowed_low_priority_task_ids << task.id }
    assigned_to_current_agent = []
    assigned_to_other_agent = []

    all_tasks.select { |task| (task.assigned_to_user_id == @user.id) ? assigned_to_current_agent << task.id : assigned_to_other_agent << task.id if (task.assigned_to_user_id.present? && task.state != 'ready') }

    channel_skill_based_task_ids = all_tasks.select { |task| task.custom_task_priority(task.skills).in?([1, 2, 3]) && task.open_to_all == false && task.skills_matched_service_channel_agents(task.skills).include?(@user.id) }.collect(&:id)
    channel_skill_based_task_ids = []
    tasks = Task.eager_load(:skills).where( arel_table[:media_channel_id]
                          .in(combined_channel_ids)
                          .and(arel_table[:state].in(%w(new ready)))
                          .or(arel_table[:assigned_to_user_id].eq(@user.id))
                          .or(open_to_all) )

    priotiy_task_ids = tasks.select{ |task| task.custom_task_priority(task.skills).in?([1, 2, 3]) && task.open_to_all == false && (user_skills & task.skills.collect(&:name)).blank? }.collect(&:id)
    total_task = tasks + task_with_high_priority + medium_priority_tasks

    priotiy_task_ids = priotiy_task_ids - channel_skill_based_task_ids

    tasks = Task.where(id: (total_task.map(&:id) + channel_skill_based_task_ids + allowed_low_priority_task_ids + assigned_to_current_agent + assigned_to_other_agent - ((priotiy_task_ids + disallowed_low_priority_task_ids) - assigned_to_current_agent)))
    can :manage, ::Task, tasks
  end
end
