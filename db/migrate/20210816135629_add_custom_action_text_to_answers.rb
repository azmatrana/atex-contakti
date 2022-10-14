class AddCustomActionTextToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :custom_action_text, :string, default: ""
    add_column :answers, :has_custom_action, :boolean, default: false
  end
end
