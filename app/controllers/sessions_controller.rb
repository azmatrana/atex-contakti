class SessionsController < Devise::SessionsController

  def destroy
    current_user.is_online = false
    current_user.is_working = false
    if current_user.has_role?(:agent) && current_user.started_working_at
      current_user.set_in_call false
      current_user.agent_in_call_status_notifier
      minutes_worked = ((::Time.current - current_user.started_working_at) / 60).floor
      current_user.timelogs.last.update_attributes(minutes_worked: minutes_worked)
    end
    super
  end

end
