class AddSmsProviderToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :sms_provider, :string, null: true
  end
end
