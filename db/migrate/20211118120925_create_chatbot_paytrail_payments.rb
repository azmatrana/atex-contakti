class CreateChatbotPaytrailPayments < ActiveRecord::Migration
  def change
    create_table :chatbot_paytrail_payments do |t|
      t.references :chatbot_order
      t.string :paid
      t.string :method
      t.datetime :payment_time
      t.string :return_auth
      t.string :url
      t.string :status, :default => "pending"
      t.string :token
      t.timestamps
    end
  end
end
