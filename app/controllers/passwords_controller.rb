class PasswordsController < Devise::PasswordsController
  prepend_before_filter :require_no_authentication

  def create
    email = params[:email]
    email ||= params[:user][:email] if params[:user]
    @user = ::User.where(email: email).first_or_create
    if @user
      # TODO: move to background
      @user.send_reset_password_instructions
      flash[:notice] = t('users.passwords.instructions_sent', email: email)
      respond_to do |format|
        format.html { redirect_to after_sending_reset_password_instructions_path_for(resource_name) }
        format.json { render json: {ok: true} }
      end
    else
      flash[:error] = t('users.passwords.email_not_found')
      respond_to do |format|
        format.html { redirect_to new_user_password_path }
        format.json { render json: {ok: false}, status: :unprocessable_entity }
      end
    end
  end

  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      set_flash_message(:notice, :updated_not_active)
      ::User::Session.deactivate(resource)
      respond_with resource, location: new_user_session_path
    else
      respond_with resource
    end
  end

end
