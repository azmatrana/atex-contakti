class SuperUi::Credentials::TavoittajaController < SuperUi::CredentialsController
  def update
    if @tavoittaja.update_attributes(tavoittaja_params)
      redirect_to edit_super_ui_credentials_url, notice: 'Tavoittaja credentials updated'
    else
      render :edit
    end
  end

  private

  def tavoittaja_params
    params.require(:credentials_tavoittaja).permit(:username, :password)
  end
end
