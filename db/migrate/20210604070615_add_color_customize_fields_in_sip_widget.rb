class AddColorCustomizeFieldsInSipWidget < ActiveRecord::Migration
  def change
    add_column :sip_widgets, :widget_button_color, :string, default: "#26828e"
    add_column :sip_widgets, :dial_color, :string, default: "#ffffff"
    add_column :sip_widgets, :dial_bg_color, :string, default: "#26828e"
  end
end
