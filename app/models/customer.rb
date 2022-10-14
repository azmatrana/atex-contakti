class Customer < ActiveRecord::Base
  before_validation :prepare_contact_phone_number
  before_validation :prepare_contact_email
  # validates :contact_phone,
  #           uniqueness: {
  #             scope: :company_id,
  #             message: I18n.t('user_dashboard.customer_modal.phone_already_in_use')
  #           },
  #           allow_nil: true
  validates :contact_email,
            uniqueness: {
              scope: :company_id,
              message: I18n.t('user_dashboard.customer_modal.email_already_in_use')
            },
            allow_nil: true
  attr_accessor :result_type

  has_many :tasks, inverse_of: :customer
  has_one :task_note,
          -> { where(state: Customer::TaskNote.states[:unsolved]) },
          class_name: 'Customer::TaskNote'
  has_one :ready_task_note,
          -> { where(state: Customer::TaskNote.states[:ready]) },
          class_name: 'Customer::TaskNote'

  private

  def prepare_contact_phone_number
    if contact_phone.blank?
      self.contact_phone = nil
      return
    end

    contact_phonelib = ::Phonelib.parse contact_phone
    if contact_phonelib.valid?
      self.contact_phone = contact_phonelib.full_e164
    else
      errors.add(:contact_phone, I18n.t('user_dashboard.customer_modal.phone_invalid'))
    end
  end

  def prepare_contact_email
    if contact_email.blank?
      self.contact_email = nil
    else
      self.contact_email.downcase!
    end
  end

  class << self
    def custom_find_by_name(full_name)
      # TODO implement this dream
      nil
    end

    def find_by_email_or_phone(email, phone, company_id)
      if email.present?
        customer = self.where(contact_email: email, company_id: company_id).first
      end
      return customer if customer
      contact_phonelib = ::Phonelib.parse phone
      if contact_phonelib.valid?
        phone_full_e164 = contact_phonelib.full_e164
        customer = self.where(contact_phone: phone_full_e164, company_id: company_id).first
        return customer if customer
      end
      nil
    end
  end
end
