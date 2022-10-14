class AddUuidToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :uuid, :uuid, null: false, default: "uuid_generate_v4()"
  end
end
