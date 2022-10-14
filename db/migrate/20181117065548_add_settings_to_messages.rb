class AddSettingsToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :settings, :json, default: { cc: [], bcc: [] }
  end
end
