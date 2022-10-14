class AddSmsBillingToCompanyStat < ActiveRecord::Migration
  def change
    add_column :company_stats, :sms_sent, :integer, null: false, default: 0
    add_column :company_stats, :sms_received, :integer, null: false, default: 0
  end
end
