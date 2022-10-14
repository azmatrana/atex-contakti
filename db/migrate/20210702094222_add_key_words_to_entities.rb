class AddKeyWordsToEntities < ActiveRecord::Migration
  def change
    add_column :entities, :key_words, :json, default:"[]";
  end
end
