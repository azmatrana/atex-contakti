class MediaChannel::Email < MediaChannel
  def settings_present?
    return true if Settings.channels.try(:email).try(:always_active)

    %i(imap_settings smtp_settings).all? do |key|
      settings = __send__(key)
      settings && settings.all_required_data_fills?
    end
  end
end
