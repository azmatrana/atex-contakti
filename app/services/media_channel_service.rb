class MediaChannelService
  def initialize(media_channel)
    @media_channel = ::MediaChannel.find(media_channel)
  end

  def check_active_state
    res = ::ImapService.test(@media_channel.imap_settings)[:success] && ::SmtpService.test(@media_channel.smtp_settings)[:success]
    if res
      @media_channel.update_columns(broken: !res)
    else
      @media_channel.update_columns(active: res, broken: !res)
    end
  end
end
