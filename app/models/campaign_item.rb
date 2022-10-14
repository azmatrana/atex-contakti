class CampaignItem < ActiveRecord::Base
  before_validation :prepare_email
  belongs_to :campaign
  has_many :agent_call_logs, as: :callable
  has_one :task

  validates :phone,
            uniqueness: {
              scope: :campaign_id,
              message: I18n.t('user_dashboard.customer_modal.phone_already_in_use')
            },
            allow_nil: true

  scope :sort_by, ->  sort_item, direction { if ["first_name", "last_name"].include?(sort_item)
    order("#{sort_item}": direction)
    end
  }

  scope :without_task, -> { where("(select count(*) from tasks where campaign_item_id=campaign_items.id) = 0") }


  def push_to_browser_refresh
    ::Danthes.publish_to "/campaign_items/#{self.campaign.id}", refresh: true
  end

  def last_call_time
    agent_call_logs.try(:last).try(:created_at).try(:strftime, '%d.%m.%y %H:%M')
  end

  private

  def prepare_email
    if email.blank?
      self.email = nil
    else
      self.email.downcase!
    end
  end
end
