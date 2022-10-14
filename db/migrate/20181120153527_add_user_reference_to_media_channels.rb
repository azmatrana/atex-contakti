class AddUserReferenceToMediaChannels < ActiveRecord::Migration
  def change
    add_reference :media_channels, :user, index: true
  end
end
