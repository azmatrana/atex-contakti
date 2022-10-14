class Chatbot::OrderProduct < ActiveRecord::Base
  belongs_to :order, class_name: 'Chatbot::Order', foreign_key: 'chatbot_order_id'
  belongs_to :product, class_name: 'Chatbot::Product', foreign_key: 'chatbot_product_id'
  
  def actual_price
    if self.with_vat
      return ((self.price*100)/(self.vat_percentage+100))
    else 
      return self.price
    end
  end
  
  def tax
    if self.with_vat
      return self.price - self.actual_price
    else 
      return self.price * self.vat_percentage / 100
    end
  end

end