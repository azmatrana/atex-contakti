require 'net/imap'
require 'mail'
require 'attachment_string_io'
require 'charlock_holmes/string' if Rails.env.production? || Rails.env.staging?

class ImapService

  def initialize(imap_settings)
    @settings = imap_settings
    @imap     = Net::IMAP.new(@settings.server_name, @settings.port, @settings.use_ssl)
    @imap.login(@settings.user_name, @settings.password)
  end

  def disconnect
    @imap.disconnect unless !@imap || @imap.disconnected?
  end

  def mark_email_as_read(message_uid)
    @imap.select('INBOX')
    @imap.uid_store(message_uid, "+FLAGS", [:Seen])
  end

  def fetch_from_imap(media_channel, start_date = nil, keepalive = false)
    messages = ::Message.in_media_channel(media_channel.id)
      .where.not(message_uid: nil).with_deleted.order(:created_at)

    # all_messages = ::Message.where.not(message_uid: nil).with_deleted.order(:created_at)

    unless start_date
      if (last_messsage = messages.last).present?
        start_date = last_messsage.created_at
      end

      start_date ||= media_channel.updated_at
    end

    since_date  = Net::IMAP.format_date(start_date - 1.day)
    search_args = ['SINCE', since_date]

    @imap.examine('INBOX')

    p search_args

    #@imap.idle do |resp|
    #  if resp.kind_of?(Net::IMAP::UntaggedResponse) and resp.name == 'EXISTS'
    #    @imap.idle_done
    #  end
    #end

    @imap.search(search_args).each do |message_id|
      fetched_msg = @imap.fetch(message_id, '(UID RFC822)')[0]
      mail        = ::Mail.new(fetched_msg.attr['RFC822'])
      msg_uid     = fetched_msg.attr['UID']
      next if messages.where(message_uid: msg_uid).exists? # || all_messages.where(message_uid: msg_uid).count > 0

      email_text = ''
      charset    = 'UTF-8'
      html       = false
      if mail.multipart?
        if mail.text_part
          email_text = mail.text_part.body.decoded
          charset    = mail.text_part.charset
        elsif mail.html_part
          email_text = mail.html_part.body.decoded
          charset    = mail.html_part.charset
          html       = true
        end
      else
        email_text = mail.body.decoded
        charset    = mail.charset
        html       = !(/text\/html/.match(mail.content_type).nil?)
      end
      begin
        if Rails.env.production? || Rails.env.staging?
          # charlock_holmes magic.
          email_text = email_text.detect_encoding!
            .encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
        end

        email_text = ::Helpers::HtmlToText.convert(email_text) if html
        # puts "EMAIL_TEXT : #{email_text}"
      rescue ::Encoding::CompatibilityError => e
        # puts "Subject: #{mail.subject}\n Body: #{email_text[0..1000]}"
        # puts "Error on parsing email with subject \"#{mail.subject}\": #{e.message}"
      end

      yield(mail, email_text, msg_uid)
    end
  rescue => e
    # puts "Error fetching email (#{@settings.server_name}): #{e.message} #{e.backtrace.join("\n")}"
  ensure
    self.disconnect unless keepalive
  end

  # ImapService.fetch_emails(MediaChannel::Email.last)
  class << self
    def fetch_emails(media_channel, start_date = nil)
      new(media_channel.imap_settings).fetch_from_imap(media_channel, start_date) do |mail, email_text, msg_uid|
        media_channel.add_fetched_email_task(
          mail, email_text, msg_uid, need_push_to_browser: true
        )
      end
    end

    def mark_as_read(media_channel, message_id)
      message = Message.find_by_id(message_id)
      if message.present? && message.marked_as_read == false
        new(media_channel.imap_settings).mark_email_as_read(message.message_uid) do
          message.update_attribute(:marked_as_read, true)
        end
      end
    end

    def test(settings)
      use_ssl = settings[:use_ssl] == '1' || settings[:use_ssl] == true
      imap    = Net::IMAP.new(settings[:server_name], settings[:port], use_ssl)
      imap.login(settings[:user_name], settings[:password])
      { success: true }
    rescue => ex
      ::Rails.logger.info "Exception connecting to IMAP server: #{ex.message} #{ex.backtrace.join("\n")}"
      { success: false, message: ex.message }
    ensure
      imap.disconnect unless !imap || imap.disconnected?
    end

    # def mark_as_read(message_id)
    #   @imap    = Net::IMAP.new(settings[:server_name], settings[:port], settings[:use_ssl])
    #   @imap.login(settings[:user_name], settings[:password])
    #   inbox = @imap.select('INBOX')
    #   email_new = @imap.search('NEW')
    # end
  end
end
