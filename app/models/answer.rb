class Answer < ActiveRecord::Base
  belongs_to :company
  belongs_to :intent
  has_many :answer_company_files
  has_many :company_files, through: :answer_company_files
  has_many :answer_buttons, dependent: :destroy
  has_many :answer_products
  has_many :answer_products, class_name: 'Chatbot::AnswerProduct', foreign_key: 'answer_id'
  has_many :products, class_name: 'Chatbot::Product', through: :answer_products
  has_many :images, class_name: 'AnswerImage', foreign_key: 'answer_id', dependent: :destroy

  scope :order_by_intent_text, -> { includes(:intent).order('intents.text ASC')  }

  validates_presence_of   :intent
  validates_uniqueness_of :intent_id, scope: :company_id

  accepts_nested_attributes_for :answer_buttons, allow_destroy: true
  accepts_nested_attributes_for :images, allow_destroy: true

  def attach_products(product_ids)
    unless product_ids.blank?
      product_ids.each do |id|
        self.products << ::Product.find_by_id(id)
      end
    end
  end
end
