class AddAutoreplyTextToMediaChannel < ActiveRecord::Migration
  def change
    add_column :media_channels, :autoreply_text, :text
  end
end
