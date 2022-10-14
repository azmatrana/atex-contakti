class MessagesController < ApplicationController
  before_action :check_agent_access
  before_action :load_task
  before_action :load_message, except: :index

  layout Proc.new { action_name == 'show' ? 'print' : 'application' }

  def index
    logger.info "==================LOGGING========================"
    render json: @task.messages.includes(:attachments).decorate, each_serializer: ::ExtendMessageSerializer
    logger.info "==================LOGGING========================"
  end

  def show
  end

  def attachment
    message = @task.messages.find(params[:id])
    attachment = message.attachments.find_by(id: params[:oid])
    #attachment = message.attachments.where(id: params[:oid]).first
    if attachment
      send_data attachment.file.read, filename: attachment.file_name
    else
      head status: :not_found
    end
  end

  private

  def load_task
    #@task = ::Task.accessible_by(current_ability).where(id: params[:task_id]).first
    @task = ::Task.accessible_by(current_ability).find_by(id: params[:task_id])
    unless @task
      raise CanCan::AccessDenied.new('Not authorized to read this Task', :read, ::Task)
    end
  end

  def load_message
    message = @task.messages.find(params[:id])
    if message
      # @message = message.decorate
      @messages = @task.messages.decorate
    else
      raise CanCan::AccessDenied.new('Not authorized to read this message', :read, ::Message)
    end
  end
end
