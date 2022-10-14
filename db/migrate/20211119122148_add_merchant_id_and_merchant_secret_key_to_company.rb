class AddMerchantIdAndMerchantSecretKeyToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :paytrail_merchant_id, :string
    add_column :companies, :paytrail_merchant_secret_key, :string
  end
end
