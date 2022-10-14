class DeletePaymentMethodTable < ActiveRecord::Migration
  def change
    drop_table :payment_methods
  end
end
