class AddSuccessAndFailureUrlToChatSetting < ActiveRecord::Migration
  def change
    add_column :chat_settings, :paytrail_payment_success_url, :string
    add_column :chat_settings, :paytrail_payment_failure_url, :string
  end
end
