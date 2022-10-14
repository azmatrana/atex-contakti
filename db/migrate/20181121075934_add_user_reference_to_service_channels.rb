class AddUserReferenceToServiceChannels < ActiveRecord::Migration
  def change
    add_reference :service_channels, :user, index: true
  end
end
