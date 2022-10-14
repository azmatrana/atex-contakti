class AttachmentsController < ApplicationController
  before_action :check_agent_access

  def show
    message = ::Message.find(params[:message_id])

    #task = ::Task.accessible_by(current_ability).where(id: message.task_id).first
    task = ::Task.accessible_by(current_ability).find_by(id: message.task_id)
    unless task
      raise CanCan::AccessDenied.new('Not authorized to read this Task', :read, ::Task)
    end

    #attachment = message.attachments.where(id: params[:attachment_id]).first
    attachment = message.attachments.find_by(id: params[:attachment_id])
    if attachment
      send_data attachment.file.read, filename: attachment.file_name
    else
      head status: :not_found
    end
  end

  def download_note_attachment
    note = ::Task::Note.find(params[:note_id])

    #attachment = note.attachments.where(id: params[:attachment_id]).first
    attachment = note.attachments.find_by(id: params[:attachment_id])
    if attachment
      send_data attachment.file.read, filename: attachment.file_name
    else
      head status: :not_found
    end
  end

  def note_attachment
    task = ::Task.find(params[:task_id])
    @attachment = task.note ? task.note.attachments : []
    render partial: '/tasks/task_messages/attachment', locals: {attachments: @attachment}
  end

  def destroy
    attachment = ::Note::Attachment.find(params[:id])
    attachment.file.remove!
    attachment.destroy
    return render json: {}, status: 200
  end
end
