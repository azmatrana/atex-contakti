# == Schema Information
#
# Table name: media_channels
#
#  id                 :integer          not null, primary key
#  service_channel_id :integer
#  type               :string(50)       default(""), not null
#  imap_settings_id   :integer
#  smtp_settings_id   :integer
#  created_at         :datetime
#  updated_at         :datetime
#  group_id           :string(255)      default(""), not null
#  deleted_at         :datetime
#  autoreply_text     :text
#  active             :boolean          default(TRUE), not null
#  broken             :boolean          default(FALSE), not null
#  name_check         :boolean          default(FALSE), not null
#  send_autoreply     :boolean          default(TRUE), not null
#  yellow_alert_hours :decimal(4, 2)
#  yellow_alert_days  :integer
#  red_alert_hours    :decimal(4, 2)
#  red_alert_days     :integer
#  chat_settings_id   :integer
#
# Indexes
#
#  index_media_channels_on_deleted_at  (deleted_at)
#

class MediaChannel::Chat < MediaChannel
  CALLBACK_SMS_GAP = 30

  def channel_type
    'chat'
  end

  def settings_present?
    true # Disable the 'not configured from ui' as there is nothing to configure
  end

  def broken?
    !id.present?
  end

  def embed_url
    "<script type=\"text/javascript\" src=\"https://atexdesk.contakti.com/chat/#{id}\"></script>"
  end

  def control_channel
    "/chat/#{id}/control"
  end

  def auto_sending_sms_hash(data)
    logger.info "SMS Autosending from Chat: #{data.inspect}"
    ::SmsSenderWorker.perform_async(
      data[:from], data[:to], data[:text], data[:company_id]
    )
  end

  private
  class << self
    def delayed_auto_sending_sms_from_chat(id, data)
      media_channel = MediaChannel::Chat.find(id)
      media_channel.auto_sending_sms_hash(data)
    end
  end

end
