class ChangeColumnNamesForKimaiDetails < ActiveRecord::Migration
  def change
    rename_column :kimai_details, :x_auth_user,  :tracker_email
    rename_column :kimai_details, :x_auth_token, :tracker_auth_token
  end
end
