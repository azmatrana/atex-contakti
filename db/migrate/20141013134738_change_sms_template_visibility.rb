class ChangeSmsTemplateVisibility < ActiveRecord::Migration
  def change
    change_column :sms_templates, :visibility, :string, limit: 20, null: false, default: ''
  end
end
