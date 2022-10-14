class SuperUi::DetailsController < SuperadminApplicationController
  def edit
  end

  def admin_params
    params.require(:super_admin).permit(:password, :password_confirmation, :current_password)
  end

  def update
    if current_super_admin.update_with_password(admin_params)
      sign_in current_super_admin, :bypass => true
      redirect_to super_ui_url, notice: 'Password changed!'
    else
      render :edit
    end
  end
end
