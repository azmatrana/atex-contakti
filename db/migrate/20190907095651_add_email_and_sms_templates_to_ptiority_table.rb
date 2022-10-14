class AddEmailAndSmsTemplatesToPtiorityTable < ActiveRecord::Migration
  def change
    add_column :priorities, :email_template, :text
    add_column :priorities, :sms_template, :text
  end
end
