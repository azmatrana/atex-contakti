class AddSmsSenderToMediaChannels < ActiveRecord::Migration
  def change
    add_column :media_channels, :sms_sender, :string, null: true
  end
end
