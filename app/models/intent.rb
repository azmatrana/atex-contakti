class Intent < ActiveRecord::Base
  belongs_to :company
  has_one :answer, dependent: :destroy
  has_many :questions, dependent: :destroy
  after_create :create_intent_on_wit
  before_destroy :delete_from_wit
  validates :text, presence: true, length: {minimum: 2}
  validates_format_of :text, with: /\A[a-z_][a-zA-Z_0-9]*\z/
  validates_uniqueness_of :text, scope: :company_id

  scope :order_by_text, -> { order('intents.text ASC')  }

  def create_intent_on_wit
    WitService.new(self.company).send_intent_to_wit(self.text)
  end

  def delete_from_wit
    wit_service = WitService.new(self.company)
    wit_service.delete_intents_from_wit(self.text)
  end
end
