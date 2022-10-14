class SuperUi::UsersController < SuperadminApplicationController

  def switch_user
    user = ::User.find(params[:id])
    if user
      redirect_to main_dashboard_path(email: user.email)
    else
      redirect_to :back
    end
  end
end
