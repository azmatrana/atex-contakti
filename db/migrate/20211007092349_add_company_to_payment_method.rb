class AddCompanyToPaymentMethod < ActiveRecord::Migration
  def change
    add_reference :payment_methods, :company, index: true, foreign_key: true
  end
end
