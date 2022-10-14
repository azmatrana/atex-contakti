require 'mail'
require 'net/smtp'
require 'ntlm/smtp'

class OrderMailSender
  def initialize(service_channel_id, order_id, mail_type="")
    @service_channel = ServiceChannel.find service_channel_id
    @order = Chatbot::Order.find order_id
    @company = @service_channel.company
    @mail_type = mail_type
    set_order_cart_email_template
  end

  def send_email
    email.delivery_handler = self
    include_attachments
    email.deliver
  end

  def include_attachments
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

      real_email.subject = email_subject
      real_email.from = settings.user_name
      real_email.to = @order.customer.email

      real_email.part(content_type: 'multipart/alternative') do |rep|
        rep.part(content_type: 'text/html') do |p|
          p.content_type 'text/html'
          p.body = email_body
        end

        rep.part(content_type: 'text/plain') do |p|
          p.content_type 'text/plain'
          p.body = strip_html email_body
        end
      end

      real_email
    end
  end

  def set_order_cart_email_template
    if @mail_type == "order_placed"
      @template = @company.cart_email_templates.get_order_placed_template
    elsif @mail_type == "send_payment_link"
      @template = @company.cart_email_templates.get_payment_link_template
    end

    if @template.blank?
      raise "no cart email templates present for type == #{@mail_type} "
    end
  end

  def email_to
    @order.customer.email
  end

  def email_subject
    return @template.subject
  end

  def email_body
    template_body = @template.body
    ac = ActionController::Base.new()
    if @mail_type == "order_placed"
      ordered_products_table = ac.render_to_string(:partial => '/order_emails/ordered_products_table', :locals => {:order => @order})
      template_body = template_body.gsub("{{products}}", ordered_products_table)
      return template_body
    elsif @mail_type == "send_payment_link"
      payment_link = ac.render_to_string(:partial => '/order_emails/payment_link', :locals => {:order => @order})
      template_body = template_body.gsub("{{payment_link}}", payment_link)
    end
  end

  def settings
    if Rails.env.development? && false
      # From vagrant to host IP => Papercut (fake SMTP server)
      @settings = ::SmtpSettings.new(server_name: '10.0.2.2', port: 25, user_name: '', password: '', auth_method: 'login')
    end

    p 'SmtpService: found service channel smtp settings'
    @settings ||= @service_channel.email_media_channel.smtp_settings
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

end
