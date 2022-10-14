class AttachmentsController < ApplicationController
  before_action :check_agent_access

  def show
    message ::Message.find(params[:message_id])

    task = ::Task.accessible_by(current_ability).where(id: message.task_id).first
    unless task
      raise CanCan::AccessDenied.new('Not authorized to read this Task', :read, ::Task)
    end

    attachment = task.attachments.where(id: params[:attachment_id]).first
    if attachment
      send_data attachment.file.read, filename: attachment.file_name
    else
      head status: :not_found
    end
  end

end
