class Api::V1::ServiceChannelsController < Api::V1::BaseController
  before_action :check_agent_access

  def index
    @service_channels = current_user.service_channels
    render json: @service_channels
  end

  def email
    @service_channels = current_user.service_channels
    @service_channels = @service_channels.reject { |sc| sc.email_media_channel.nil? || sc.email_media_channel.broken }
    render json: @service_channels
  end
end
