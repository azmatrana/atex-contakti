class Chatbot::PaytrailPayment < ActiveRecord::Base
  belongs_to :order, class_name: 'Chatbot::Order' , foreign_key: 'chatbot_order_id'
  

  before_create :create_paytrail_payment_request
  after_create :send_email

  def create_paytrail_payment_request
    PaytrailClient.configuration do |config|
      config.merchant_id     = self.order.company.paytrail_merchant_id
      config.merchant_secret = self.order.company.paytrail_merchant_secret_key
    end

    site_origin = Rails.env.development? ? "http://6269-119-63-139-29.ngrok.io" : Settings.host_origin
    token = PaytrailClient::Payment.create(
      order_number: self.order.id,
      currency: 'EUR',
      locale: 'fi_FI',
      url_set: {
        success: site_origin + "/paytrail_payments/success",
        failure: site_origin + "/paytrail_payments/failure",
        notification: site_origin + "/paytrail_payments/notification"
      },
      price: self.order.total
    )

    if !token["errorMessage"].present?
      self.assign_attributes(
        url: token['url'],
        token: token['token'],
      )
    else
      puts "Error"
    end
  end

  def send_email
    OrderMailSender.new(self.order.service_channel_id, self.order.id, "send_payment_link").send_email
  end

end
