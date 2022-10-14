class SignInAsController < ApplicationController
  include SignInAs::Concerns::RememberAdmin

  #layout 'admin/application'

  def sign_in_as
    new_user = User.find(params[:user_id])

    if can?(:manage, new_user)
      logger.debug 'In SignInAsController#create with can? true'
      self.remember_admin_id = current_user.id
      admin_id = current_user.id
      #sign_out current_user
      sign_in :user, new_user
      session[:original_admin_id] = admin_id
    end

    redirect_to '/'
  end

  def back
    # Is this massively insecure? Save that shit in session? Session is stored in db so prolly not?
    admin_id = session[:original_admin_id]
    self.remember_admin_id = admin_id
    #sign_out current_user
    logger.debug "CURRENT USER SESSION ORIG ADMIN ID: #{admin_id}"
    admin = User.find(admin_id)
    sign_in :user, admin
    @current_user = admin
    session.delete :original_admin_id
    redirect_to main_dashboard_path
  end


end
