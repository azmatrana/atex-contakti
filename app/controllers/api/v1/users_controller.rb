class Api::V1::UsersController < Api::V1::BaseController
  before_action :check_agent_access

  def index
    resource = current_user
    raise CanCan::AccessDenied unless resource

    render json: {
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
  end

  def get_kimai_detail
    render json: {credentials: current_user.kimai_detail, tracker_url: current_user.kimai_tracker_api_url}
  end

  def recepient_emails
    render json: current_user.recepient_emails.pluck(:email)
  end

  def update
    @user = User.find(current_user.id)
    if @user.id != params[:id].to_i
      raise "Updating another user is not allowed"
    end

    p = user_params

    # Prevent validation from firing if passwords aren't filled in
    p[:password] = nil if p[:password] === ''
    p[:password_confirmation] = nil if p[:password_confirmation] === ''
    if @user.update(p)
      sign_in @user, :bypass => true
      flash[:notice] = I18n.t('users.details.updated_details')
      if user_params[:password]
        ::User::Session.exclusive(@user, cookies.signed['session_id'])
      end

      render json: {
        id: @user.id,
        first_name: @user.first_name,
        last_name: @user.last_name,
        token: @user.authentication_token!,
        service_channels: @user.service_channels,
        media_channels: @user.media_channels
      }
    end
  end

  private

    def user_params
      @user_params ||= params.permit(
        :first_name,
        :last_name,
        :title,
        :mobile,
        :email,
        :password,
        :password_confirmation,
        :skills,
        :signature
      )
    end

end
