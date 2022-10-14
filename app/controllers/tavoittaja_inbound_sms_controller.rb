class TavoittajaInboundSmsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :authenticate_user!, :update_current_session, only: [:create]

  def create
    if params[:sender].present? && params[:recipient].present?
      result = TavoittajaInboundSmsService.call(sms_params: params)

      if result.success?
        head :ok
      else
        head :unprocessable_entity
      end
    elsif params[:source].present? && params[:dest].present?
      result = LabyrinttiInboundSmsService.call(sms_params: params)

      if result.success?
        render plain: "", status: :ok
      else
        render plain: "error=Failed", status: :unprocessable_entity
      end
    end
  end
end
