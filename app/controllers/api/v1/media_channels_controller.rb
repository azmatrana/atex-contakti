class Api::V1::MediaChannelsController < Api::V1::BaseController
  before_action :check_agent_access

  def index
    @media_channels = current_user.media_channels
    render json: @media_channels, each_serializer: ::MediaChannelSerializer
  end
end
