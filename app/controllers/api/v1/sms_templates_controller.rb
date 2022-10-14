class Api::V1::SmsTemplatesController < Api::V1::BaseController
  before_action :check_agent_access

  def index
    @templates = ::SmsTemplate.accessible_by(current_ability)
    render json: @templates.decorate
  end
end
