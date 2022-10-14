class Api::V1::MessagesController < Api::V1::BaseController
  before_action :check_agent_access
  before_action :load_task

  def index
    p "=======================LOGGING FROM API METHOD=================="
    p @task.messages.includes(:attachments).decorate
    render json: @task.messages.includes(:attachments).decorate, each_serializer: ::ExtendMessageSerializer
  end

  private

  def load_task
    @task = ::Task.accessible_by(current_ability).where(id: params[:task_id]).first
    unless @task
      raise CanCan::AccessDenied.new('Not authorized to read this Task', :read, ::Task)
    end
  end
end
