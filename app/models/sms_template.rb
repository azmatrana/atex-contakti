# == Schema Information
#
# Table name: sms_templates
#
#  id                 :integer          not null, primary key
#  title              :string(100)      default(""), not null
#  text               :text
#  kind               :string(20)       default(""), not null
#  service_channel_id :integer
#  location_id        :integer
#  company_id         :integer
#  author_id          :integer
#  created_at         :datetime
#  updated_at         :datetime
#  visibility         :string(20)       default(""), not null
#

class SmsTemplate < ActiveRecord::Base

  belongs_to :service_channel
  belongs_to :location
  belongs_to :company

  validates :kind, inclusion: { :in => %w[agent manager] }
  validates :title, :text, presence: true
  validates :title, uniqueness: { scope: :company_id, unless: :for_agent? }
  validates :title, uniqueness: { scope: :service_channel_id, if: :for_agent? }

  scope :for_agent,   -> { where(kind: :agent)   }
  scope :for_manager, -> { where(kind: :manager) }

  def for_agent?
    self.kind == 'agent'
  end

end
