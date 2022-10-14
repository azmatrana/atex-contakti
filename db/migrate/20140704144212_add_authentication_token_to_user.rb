class AddAuthenticationTokenToUser < ActiveRecord::Migration
  def change
    add_column :users, :authentication_token, :string, limit: 36, null: false, default: ''
  end
end
