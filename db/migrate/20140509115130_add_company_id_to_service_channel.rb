class AddCompanyIdToServiceChannel < ActiveRecord::Migration
  def change
    add_column :service_channels, :company_id, :integer
  end
end
