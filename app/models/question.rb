include BotMessageHelper
class Question < ActiveRecord::Base
  belongs_to :company
  belongs_to :intent
  accepts_nested_attributes_for :intent
  validates :intent_id, presence: true
  validates :text, presence: true

  before_validation :prepare_text
  after_create :train_bot_on_question
  after_destroy :delete_intent
  before_destroy :delete_from_wit, prepend: true
  
  scope :order_by_intent_text, -> { includes(:intent).order('intents.text ASC')  }

  def to_hash
    hash = { :question => self.text, :intent => self.intent.text, :entities => [], :traits => [] }
  end

  def train_bot_on_question
    wit_service = WitService.new(self.company)
    res = wit_service.send_utterance_to_wit(self.to_hash)
    puts res
  end

  def delete_from_wit
    question_array = [{:text => self.text}]
    wit_service = WitService.new(self.company)
    wit_service.delete_utterances_from_wit(question_array)
  end

  def delete_intent
    intent = self.intent
    unless intent.questions.present?
      intent.destroy
    end
  end

  private

  def prepare_text
    if text.present?
      self.text = self.text.gsub("\n", '').squish
    end
  end

end
