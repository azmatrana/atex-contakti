class AddVisibilityToSmsTemplate < ActiveRecord::Migration
  def change
    add_column :sms_templates, :visibility, :string, limit: 20, null: false, default: 'service_channel'
  end
end
