class RecepientEmail < ActiveRecord::Base
  before_validation :prepare_email

  belongs_to :user

  private

  def prepare_email
    if email.blank?
      self.email = nil
    else
      self.email = self.email.downcase.strip
    end
  end
end
