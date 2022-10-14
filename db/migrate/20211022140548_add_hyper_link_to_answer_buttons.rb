class AddHyperLinkToAnswerButtons < ActiveRecord::Migration
  def change
    add_column :answer_buttons, :hyper_link, :string, default: ""
  end
end
