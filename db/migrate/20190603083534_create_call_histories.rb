class CreateCallHistories < ActiveRecord::Migration
  def change
    create_table :call_histories do |t|
      t.string :remote
      t.boolean :incoming
      t.string :duration
      t.references :user, index: true

      t.timestamps
    end
  end
end
