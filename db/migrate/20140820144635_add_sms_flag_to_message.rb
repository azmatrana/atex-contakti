class AddSmsFlagToMessage < ActiveRecord::Migration
  def change
    add_column :messages, :sms, :boolean, null: false, default: false
  end
end
