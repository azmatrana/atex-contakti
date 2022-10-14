require 'mail'
require 'net/smtp'
require 'ntlm/smtp'

class SmtpService
  def initialize(message)
    @message = message
  end

  def send_email
    email.delivery_handler = self
    include_attachments
    email.deliver
  end

  def include_attachments
    @message.attachments.each do |attachment|
#     mail.add_file(:filename => a.original_filename, :content => a.tempfile.read)
     email.add_file(filename: attachment.file_name, content: attachment.file.read)

#      email.attachments[attachment.file_name] = {
#        content: attachment.file.read
#      }
    end
  end

  def strip_html(html)
    body_parts = []

    Nokogiri::HTML(html).traverse do |node|
      if node.text? and (content = node.content ? node.content.strip : nil).present?
        body_parts << content
      elsif node.name == 'a' and (href = node.attr('href'))
        body_parts << href
      end
    end

    body_parts.join "\r\n"
  rescue
    ActionView::Base.full_sanitizer.sanitize html
  end

  def email
    @email ||= begin
      real_email = ::Mail::Message.new
      real_email.charset = 'UTF-8'
      real_email.content_transfer_encoding = '8bit'
      real_email.subject = @message.title
      real_email.from = @message.from
      real_email.to = @message.to
      real_email.cc = @message.cc if @message.cc.present?
      real_email.bcc = @message.bcc if @message.bcc.present?

      real_email.part(content_type: 'multipart/alternative') do |rep|
        rep.part(content_type: 'text/html') do |p|
          p.content_type 'text/html'
          p.body = @message.description
        end

        rep.part(content_type: 'text/plain') do |p|
          p.content_type 'text/plain'
          p.body = strip_html @message.description
        end
      end

#      html_part = Mail::Part.new
#      html_part.body = @message.description
#      html_part.content_type = 'text/html'
#      real_email.html_part = html_part

#      text_part = Mail::Part.new
#      text_part.body = strip_html @message.description
#      real_email.text_part = text_part

      real_email
    end
  end

  def settings
    if Rails.env.development? && false
      # From vagrant to host IP => Papercut (fake SMTP server)
      @settings = ::SmtpSettings.new(server_name: '10.0.2.2', port: 25, user_name: '', password: '', auth_method: 'login')
    end

    p 'SmtpService: find smtp settings'
    if !!(@message.try(:task).try(:service_channel).try(:web_form_media_channel).try(:smtp_settings).try(:user_name) && @message.try(:task) && @message.task.media_channel.web_form?)
      p 'SmtpService: found web form smtp settings'
      @settings ||= @message.task.service_channel.web_form_media_channel.smtp_settings
    elsif @message.task.use_assigned_user_email_settings && @message.task.agent && @message.task.agent.smtp_settings
      p 'SmtpService: found user smtp settings'
      @settings ||= @message.task.agent.smtp_settings
    else
      p 'SmtpService: found service channel smtp settings'
      @settings ||= @message.task.service_channel.email_media_channel.smtp_settings
    end
  end

  def settings=(settings)
    @settings = settings
  end

  def smtp_settings
    if Rails.env.development? && false
      # From vagrant to host IP => Papercut (fake SMTP server), disable authentication
      @smtp_settings = {
          address: '10.0.2.2',
          port: 25
      }
    end

    if settings.class.name == 'SmtpSettings' && settings.use_contakti_smtp?
      @smtp_settings = Settings.smtp
    else
      tls = nil
      enable_starttls_auto = nil
      if settings.port.to_i == 465
        tls = true if settings.use_ssl?
      elsif settings.port.to_i == 587
        enable_starttls_auto = true if settings.use_ssl?
      end

      domain = settings.user_name.include?('@') ? settings.user_name.partition('@').last : 'localhost'

      if settings.server_name == "smtp.office365.com" || settings.server_name == "smtp-mail.outlook.com"
        ssl = false
      else
        ssl = settings.use_ssl?
      end
      @smtp_settings ||= {
        address:               settings.server_name,
        port:                  settings.port,
        domain:                domain,
        user_name:             settings.user_name,
        password:              settings.password,
        authentication:        settings.get_auth_method,
        enable_starttls_auto:  enable_starttls_auto,
        ssl:                   ssl,
        tls:                   tls,
      }
    end

    p @smtp_settings

    @smtp_settings
  end

  def delivery_handler
    @delivery_handler ||= ::Mail::SMTP.new(smtp_settings)
  end

  def deliver_mail(mail)
    delivery_handler.deliver!(mail)
  end

  class << self
    def test(settings)
      use_ssl = settings[:use_ssl] == '1' || settings[:use_ssl] == true
      username = settings[:user_name].blank? ? nil : settings[:user_name]
      password = settings[:password].blank? ? nil : settings[:password]
      smtp = ::Net::SMTP.new(settings[:server_name], settings[:port])
      smtp.read_timeout = 5 # in seconds
      if settings[:port].to_i == 465
        smtp.enable_tls() if use_ssl
      elsif settings[:port].to_i == 587
        smtp.enable_starttls() if use_ssl
      end
      helo_domain = settings[:user_name].include?('@') ? settings[:user_name].partition('@').last : 'localhost'
      smtp.start(
        helo_domain, username, password, :login
      )
      smtp.finish
      { success: true }
    rescue => ex
      ::Rails.logger.info "Exception on establishing connection with SMTP server: #{ex.message}"
      { success: false, message: ex.message }
    end
  end
end
