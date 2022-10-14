class Chatbot::Order < ActiveRecord::Base
  
  include TimeScopes
  
    belongs_to :company
    belongs_to :service_channel
    belongs_to :customer
    belongs_to :ticket, class_name: 'Task', foreign_key: 'task_id'
    has_many :order_products, class_name: 'Chatbot::OrderProduct',foreign_key: 'chatbot_order_id' , dependent: :destroy
    has_one :chatbot_paytrail_payment, class_name: 'Chatbot::PaytrailPayment' , foreign_key: 'chatbot_order_id', dependent: :destroy
    belongs_to :shipment_method, foreign_key: 'shipment_method_id'
    accepts_nested_attributes_for :order_products

    after_commit :push_task_to_browser, on: :create
    before_create :set_ticket_customer
    after_create :check_payment_actions

    def chat_inquiry_fields_json
      return JSON(inquiry_fields_data)
    end

    def price_without_taxes
      sum = 0;
      self.order_products.map{|p| (sum += (p.actual_price * p.quantity))}
      sum
    end

    def taxes
      taxes = 0;
      self.order_products.map{|p| (taxes += (p.tax * p.quantity))}
      taxes
    end

    def push_task_to_browser
       self.ticket.try(:push_task_to_browser)
    end

    def send_email
      OrderMailSender.new(self.service_channel_id, self.id, "order_placed").send_email
    end

    def check_payment_actions
      if self.checkout_method == 'checkout_paytrail'
        self.create_chatbot_paytrail_payment
      else
        self.send_email
      end
    end

    def set_ticket_customer
      customer_id = ::Customer.where(
          contact_email: self.customer.email.downcase,
          company_id: self.company_id
        ).select(:id).first.try(:id)
      self.ticket.update_attribute('customer_id', customer_id)
    end

end
