class AddLocaleToReports < ActiveRecord::Migration
  def change
    add_column :reports, :locale, :string, limit: 20
  end
end
