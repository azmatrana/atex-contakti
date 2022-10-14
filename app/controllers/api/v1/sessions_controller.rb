class Api::V1::SessionsController < Api::V1::BaseController
  skip_before_filter :authenticate_user_from_token!, only: [:create]
  skip_before_filter :authenticate_user!, only: [:create]
  before_action :check_agent_access, only: [:check]

  def create
    resource = User.find_for_database_authentication(email: params[:user][:email])
    raise CanCan::AccessDenied unless resource

    resource.remember_me = (params[:user][:remember_me] == 'true')
    if resource.valid_password?(params[:user][:password])
      sign_in(:user, resource)
      render status: 201, json: {
                            id: resource.id,
                            first_name: resource.first_name,
                            last_name: resource.last_name,
                            title: resource.title,
                            mobile: resource.mobile,
                            signature: resource.signature,
                            token: resource.authentication_token!,
                            service_channels: resource.service_channels,
                            media_channels: resource.media_channels
                        }
    else
      raise CanCan::AccessDenied
    end
  end

  def destroy
    current_user.forget_me!
    sign_out(current_user)
    render json: :ok
  end

  def check
    render json: {
      success: true
    }
  end
end
