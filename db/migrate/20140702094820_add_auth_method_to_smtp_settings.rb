class AddAuthMethodToSmtpSettings < ActiveRecord::Migration
  def change
    add_column :smtp_settings, :auth_method, :string, limit: 20, null: false, default: ''
  end
end
