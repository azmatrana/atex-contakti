class AddSipSettingsToUsers < ActiveRecord::Migration
  def change
    add_reference :users, :sip_settings, index: true
  end
end

