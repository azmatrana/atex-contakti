class MessageService
  attr_reader :message

  def initialize(message, params)
    @message, @params = message, params
  end

  def reply_for(task, skip_save=false)
    @message = build_reply_for(task)
    task.save(validate: false)
    process_attachments
    @message
  end

  def build_reply_for(task)
    filter_message_to(task)
    @message = task.messages.build(reply_params)
    if use_agent_web_form_settings?(task)
      @message.from = task.service_channel.web_form_media_channel.imap_settings.from
    elsif use_agent_email_settings?(task)
      @message.from = task.agent.imap_settings.from
    elsif !sms? && forward?
       @message.from = task.service_channel.email_media_channel.imap_settings.from
    else
      @message.from = task.service_channel.email_media_channel.imap_settings.from unless (sms? || internal? || task.service_channel.email_media_channel.nil? || task.service_channel.email_media_channel.imap_settings.nil?)
    end

    if sms?
      reply_to_phonelib = ::Phonelib.parse @params[:reply][:to]
      if reply_to_phonelib.valid?
        reply_to = reply_to_phonelib.full_e164
        task.data_will_change!

        begin
          caller_name = ::Fonnecta::Contacts.new(task.company, reply_to).search
          task.data['caller_name'] = caller_name.presence || I18n.t('tasks.default_from')
        rescue Exception => e
          logger.warn "Fonnecta name check failed with #{e.message}"
          task.data['caller_name'] = I18n.t('tasks.default_from')
        end
      end
      ::Rails.logger.info "reply_to #{reply_to}"
      @message.to = reply_to || task.messages.first.from
    end

    @message.channel_type = task.media_channel.channel_type

    if sms? || internal?
      @message.to = "Internal" if internal? && @message.to.blank?
    end

    @message.number = task.messages.count + 1
    @message.is_internal = internal?
    @message.sms = sms?
    @message
  end

  private

  def forward?
    @params[:reply][:is_forward].present?
  end

  def internal?
    @params[:reply][:is_internal] == 'true'
  end

  def sms?
    @params[:reply][:is_sms].present?
  end

  def filter_message_to(task)
    email_recipient = @params[:reply][:to].split(',').collect(&:strip).uniq
    # imap_settings = task.try(:service_channel).try(:email_media_channel).try(:imap_settings)
    # email_recipient = email_recipient.join(' ').gsub(imap_settings.try(:from_email), '').split
    @params[:reply][:to] = email_recipient.to_sentence(:last_word_connector => ', ', :two_words_connector => ', ')
  end

  def process_attachments
    if @params[:attachments]
      @params[:attachments].each do |attachment|
        @message.attachments.build(
          file_name: attachment.original_filename,
          file_size: attachment.size,
          content_type: attachment.content_type,
          file: attachment
        )
      end
    end

    if @params["company_files_ids"].present?
      @params["company_files_ids"].each do |id|
        company_file = CompanyFile.find_by_id(id)
        if company_file.present?
          @message.attachments.build(
            file_name: company_file.file_name,
            file_size: company_file.file_size,
            content_type: company_file.file_type,
            file: ::AttachmentStringIO.new(company_file.file_name, company_file.file.read)
          )
        end
      end
    end
  end

  def reply_params
    @params.require(:reply).permit(:title, :description, :in_reply_to_id, :is_internal, :to, :cc, :bcc)
  end

  def use_agent_email_settings?(task)
    !!(task.use_assigned_user_email_settings && task.try(:agent).try(:imap_settings).try(:from))
  end

  def use_agent_web_form_settings?(task)
    !!(task.try(:service_channel).try(:web_form_media_channel).try(:imap_settings).try(:from) && task.media_channel.web_form?)
  end
end
