class Contact < ActiveRecord::Base
  before_validation :prepare_email
  belongs_to :company
  belongs_to :agent, class_name: 'User', foreign_key: 'agent_id'

  # validates :phone,
  #           uniqueness: {
  #             scope: :company_id,
  #             message: I18n.t('user_dashboard.customer_modal.phone_already_in_use')
  #           },
  #           allow_nil: true
  # validates :email,
  #           uniqueness: {
  #             scope: :company_id,
  #             message: I18n.t('user_dashboard.customer_modal.email_already_in_use')
  #           },
  #           allow_nil: true

  scope :sort_by, ->  sort_item, direction { if ["first_name", "last_name"].include?(sort_item)
    order("#{sort_item}": direction)
    end
  }

  def self.sql_find_contacts_by_plain_phone(_phone, current_user)
    if current_user.has_role? :agent
      ActiveRecord::Base.connection.execute("SELECT * FROM(SELECT *, TRANSLATE(phone, '-', '') AS total_hours FROM contacts) as data where data.total_hours = '#{_phone}' AND agent_id = #{current_user.id}")
    else
      ActiveRecord::Base.connection.execute("SELECT * FROM(SELECT *, TRANSLATE(phone, '-', '') AS total_hours FROM contacts) as data where data.total_hours = '#{_phone}' AND company_id = #{current_user.company.id}")
    end
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
