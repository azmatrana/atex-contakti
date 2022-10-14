class ChangeTypeOfInReplyToIdInMessages < ActiveRecord::Migration
  def change
    change_column :messages, :in_reply_to_id, :string
  end
end
