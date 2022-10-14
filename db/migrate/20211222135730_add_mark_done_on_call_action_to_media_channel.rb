class AddMarkDoneOnCallActionToMediaChannel < ActiveRecord::Migration
  def change
    add_column :media_channels, :mark_done_on_call_action, :boolean, default: false
  end
end
