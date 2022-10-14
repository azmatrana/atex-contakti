class CreateSipWidgets < ActiveRecord::Migration
  def change
    create_table :sip_widgets do |t|
      t.references :sip_settings, index: true

      t.string :button_1
      t.string :button_1_extension

      t.string :button_2
      t.string :button_2_extension

      t.string :button_3
      t.string :button_3_extension

      t.string :button_3
      t.string :button_3_extension

      t.string :button_4
      t.string :button_4_extension

      t.string :button_5
      t.string :button_5_extension

      t.string :button_6
      t.string :button_6_extension

      t.timestamps
    end
  end
end
