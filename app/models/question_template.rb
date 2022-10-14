class QuestionTemplate < ActiveRecord::Base
  # This model is for logging all the questions which wit is unable to understand
  belongs_to :company
  before_validation :prepare_text
  after_create :push_to_browser

  def push_to_browser
    if self.company_id.present?
      ::Danthes.publish_to "/understandings/#{self.company_id}", self.as_json
    end
  end

  private

  def prepare_text
    if text.present?
      self.text = self.text.gsub("\n", '').squish
    end
  end
end
