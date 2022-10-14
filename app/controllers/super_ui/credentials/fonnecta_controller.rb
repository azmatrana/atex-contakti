class SuperUi::Credentials::FonnectaController < SuperUi::CredentialsController
  def update
    if @fonnecta.update_attributes(fonnecta_params)
      redirect_to edit_super_ui_credentials_url, notice: 'Fonnecta credentials updated'
    else
      render :edit
    end
  end

  private

  def fonnecta_params
    params.require(:fonnecta_credential).permit(:client_id, :client_secret)
  end
end
