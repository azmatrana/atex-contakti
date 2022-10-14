class LabyrinttiInboundSmsService
  include Interactor

  def call
    TavoittajaInboundSmsService.call(sms_params: {sender: context.sms_params[:source], recipient: context.sms_params[:dest], message: context.sms_params[:text]})
  rescue StandardError => error
    Rails.logger.error error.message
    context.fail!(message: error.message)
  end
end
