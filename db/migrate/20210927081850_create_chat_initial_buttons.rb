class CreateChatInitialButtons < ActiveRecord::Migration
  def change
    create_table :chat_initial_buttons do |t|
      t.string :title
      t.references :chat_settings
    end
    add_column :chat_settings, :enable_initial_buttons, :boolean, default: true
  end
end
