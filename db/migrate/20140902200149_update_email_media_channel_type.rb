class UpdateEmailMediaChannelType < ActiveRecord::Migration
  def up
    updated_items = ::MediaChannel.unscoped.where(type: 'EmailMediaChannel').update_all(type: 'MediaChannel::Email')
    say "Updated #{updated_items} items"
  end

  def down
    # do nothing
  end
end
