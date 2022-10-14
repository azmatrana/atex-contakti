#  this media channel - private, only for sending messages from Agent

class MediaChannel::Agent < MediaChannel
  def service_channel
    # return super 
    # if service_channel_id.present?

    # sc = ServiceChannel.create(
    #   name: I18n.t('service_channels.private_agent_channel_name'),
    #   user_id: user_id,
    #   company_id: company_id,
    #   locations: user.locations,
    #   yellow_alert_hours: 0,
    #   red_alert_hours: 6
    # )

    # sc.users << user

    # update service_channel_id: sc.id

    # sc
    return self.user.service_channel
  end

  def settings_present?
    return true if Settings.channels.try(:email).try(:always_active)

    %i(imap_settings smtp_settings).all? do |key|
      settings = __send__(key)
      settings && settings.all_required_data_fills?
    end
  end

  def company_id
    user.try(:company_id)
  end
end
