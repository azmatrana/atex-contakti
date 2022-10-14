# == Schema Information
#
# Table name: preferences
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  company_id :integer
#  state      :boolean          default(FALSE)
#  created_at :datetime
#  updated_at :datetime
#

class Preference < ActiveRecord::Base
  ITEMS = %w{skills_management new_task email_sender customer_registry chat facebook}
  DEFAULT_PREFERENCE = true
  belongs_to :company

  def self.method_missing(m, *args, &block)
    match = m.to_s.match(/prefers_having_(.*)\?/)
    if match
      preference = self.find_by_company_id_and_name(args[0].id, match[1])
      return preference.present? ? !!preference.state : Preference::DEFAULT_PREFERENCE
    else
      super
    end
  end
end
