class AddAllowCallTranslationInCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :allow_call_translation, :boolean, default: false
  end
end
