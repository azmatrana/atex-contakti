class RemoveCheckoutFormatAndAddPaytrailAndTicketToChatSettings < ActiveRecord::Migration
  def change
    remove_column :chat_settings, :checkout_format
    add_column :chat_settings, :checkout_paytrail, :boolean, default: false
    add_column :chat_settings, :checkout_ticket, :boolean, default: true
  end
end
