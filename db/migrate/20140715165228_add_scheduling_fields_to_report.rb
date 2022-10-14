class AddSchedulingFieldsToReport < ActiveRecord::Migration
  def change
    add_column :reports, :scheduled, :string, null: false, default: ''
    add_column :reports, :last_sent_at, :datetime
  end
end
