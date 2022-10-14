class ImapSettings < ActiveRecord::Base
  if Rails.env.development?
    REQUIRED_FIELDS = %i[server_name port]
  else
    REQUIRED_FIELDS = %i[server_name user_name password port]
  end

  has_one :media_channel
  belongs_to :company

  def from
    if self.from_full_name.present? && self.from_email.present?
      "#{self.from_full_name} <#{self.from_email}>"
    else
      self.from_email.present? ? self.from_email : self.user_name
    end
  end

  def all_required_data_fills?
    REQUIRED_FIELDS.all? do |key|
      __send__(key).present?
    end
  end
end
