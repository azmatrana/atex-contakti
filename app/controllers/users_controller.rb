
class   UsersController < ApplicationController

  def user_params
    @user_params ||= params.require(:user).permit(:first_name, :last_name, :title, :mobile, :email, :password, :password_confirmation, :skills, :signature)
  end

  def details
    @user = current_user
    if(Kimai::KimaiDetail.all != [])
      if(Kimai::KimaiDetail.find_by(user_id: current_user.id) != nil)
        @kimai_details = Kimai::KimaiDetail.where(user_id: current_user.id).last
      end
    end
  end

  def update
    @user = User.find(current_user.id)
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
    end
    redirect_to details_path
  end

  def update_kimai_credentials
    @kimai_detail = @current_user.kimai_detail ||= @current_user.build_kimai_detail
    @kimai_detail.tracker_email = params[:tracker_email]
    @kimai_detail.tracker_auth_token = params[:tracker_auth_token]
  end

  def set_locales
    @user = User.find_by_id(current_user.id)
    @user[:locale] = params[:locale]
    if @user.save
      redirect_to details_path
    end
  end


  def change_online_status
    is_online = params[:online] == 'true'
    current_user.set_online is_online
    Danthes.publish_to "/users_online/#{current_user.id.to_s}", {:online => is_online.to_s}
    render :nothing => true
  end

  def danthes_subscribe_user_online
    channel = "/users_online/#{current_user.id}"
    render json: ::Danthes.subscription(channel: channel)
  end

  def mark_as_seen
    current_user.last_seen_tasks = DateTime.current
    current_user.save!
    render :nothing => true
  end

  
end
