class Chatbot::Product < ActiveRecord::Base
  has_many :answer_products
  has_many :answers, through: :answer_products
  has_many :order_products
  belongs_to :company
  belongs_to :vat
  validates_presence_of :title
  validates_presence_of :price
  has_many :images, class_name: 'Chatbot::ProductImage', foreign_key: 'chatbot_product_id', dependent: :destroy
  has_many :attachments, class_name: 'Chatbot::ProductAttachment', foreign_key: 'chatbot_product_id', dependent: :destroy
  accepts_nested_attributes_for :images, allow_destroy: true
  accepts_nested_attributes_for :attachments, allow_destroy: true

  before_validation :prepare_description

  CURRENCY = ['€', '£', '$']

  def answers_count
    self.answers.count
  end

  def actual_price
    if self.with_vat && self.vat
      return ((self.price*100)/(self.vat.vat_percentage+100))
    else
      return self.price
    end
  end

  def tax_amount
    if self.with_vat && self.vat
      return self.price - self.actual_price
    elsif !self.with_vat && self.vat
      return self.price * self.vat.vat_percentage / 100
    else
      return 0
    end
  end

  def prepare_description
    if description.blank?
      self.description = ''
    end
  end
end
