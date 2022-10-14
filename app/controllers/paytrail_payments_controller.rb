class PaytrailPaymentsController < ApplicationController

  skip_before_action :authenticate_user!

  def success
    @payment = Chatbot::PaytrailPayment.find_by_chatbot_order_id(params[:ORDER_NUMBER])
    @payment.update_columns(
      payment_time: Time.at(params[:TIMESTAMP].to_i),
      paid: params[:PAID],
      method: params[:METHOD],
      return_auth: params[:RETURN_AUTHCODE],
      status: "paid"
    )
    @payment.order.send_email
    redirect_to ::Helpers::CommonUtils.string_to_url(@payment.order.service_channel.chat_media_channel.chat_settings.paytrail_payment_success_url)
  end

  def failure
    @payment = Chatbot::PaytrailPayment.find_by_chatbot_order_id(params[:ORDER_NUMBER])
    @payment.update_columns(
      status: "failed"
    )
    redirect_to ::Helpers::CommonUtils.string_to_url(@payment.order.service_channel.chat_media_channel.chat_settings.paytrail_payment_failure_url)
  end

  def notification
  end

  private

  def paytrail_payment_params
    params.require(:paytrail_payment).permit(
      :chatbot_orders_id,
      :paid,
      :method,
      :payment_time,
      :return_auth,
      :token,
      :url,
      :status
    )
  end

end