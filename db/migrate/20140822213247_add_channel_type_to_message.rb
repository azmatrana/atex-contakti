class AddChannelTypeToMessage < ActiveRecord::Migration
  def change
    # caching field
    add_column :messages, :channel_type, :string, limit: 20, null: false, default: 'email'
  end
end
