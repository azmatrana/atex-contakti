class AddAutoreplyEmailSubjectToMediaChannel < ActiveRecord::Migration
  def change
    add_column :media_channels, :autoreply_email_subject, :string
  end
end
