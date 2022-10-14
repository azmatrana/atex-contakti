class AddSignatureToServiceChannel < ActiveRecord::Migration
  def change
    add_column :service_channels, :signature, :string
  end
end
