class ChangeDefaultForSendAutoreplyInMediaChannel < ActiveRecord::Migration
  def change
    MediaChannel.where("type IN ('MediaChannel::WebForm','MediaChannel::Email') ").update_all(:send_autoreply => false)
  end
end
