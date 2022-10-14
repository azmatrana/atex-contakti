class SuperUi::CredentialsController < SuperadminApplicationController
  before_action :load_fonnecta, :load_tavoittaja, only: %i[edit update]

  def edit
    @fonnecta_form = true
  end

  private

  def load_fonnecta
    @fonnecta = ::Fonnecta::Credential.first_or_initialize
  end

  def load_tavoittaja
    @tavoittaja = ::Credentials::Tavoittaja.first_or_initialize
  end
end
