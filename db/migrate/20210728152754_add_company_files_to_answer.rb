class AddCompanyFilesToAnswer < ActiveRecord::Migration
  def change
    add_column :answers, :company_file_id, :integer
  end
end
