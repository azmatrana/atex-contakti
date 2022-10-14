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

class MediaChannel::WebForm < MediaChannel

  def channel_type
    'web_form'
  end

  def get_message_from(mail, email_text)
    match = email_text.match(email_regex)
    if match && match.to_s != mail.to.first
      match.to_s
    else
      mail.from.first
    end
  end

  def email_regex
    # non-strict ::Devise.email_regexp
    /[-0-9a-zA-Z.+_]+@[-0-9a-zA-Z.+_]+\.[a-zA-Z]{2,4}/
  end

  def settings_present?
    %i(imap_settings smtp_settings).all? do |key|
      settings = __send__(key)
      settings && settings.all_required_data_fills?
    end
  end

end
