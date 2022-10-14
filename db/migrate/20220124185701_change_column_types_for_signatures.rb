class ChangeColumnTypesForSignatures < ActiveRecord::Migration
  def change
    change_column :users, :signature, :text
    change_column :service_channels, :signature, :text
  end
end
