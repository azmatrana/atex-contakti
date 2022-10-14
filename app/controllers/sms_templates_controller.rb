class SmsTemplatesController < ApplicationController
  
  def create
    load_sms_template
    @sms_template.attributes = sms_template_params
    @sms_template.author_id  = current_user.id
    @sms_template.company_id = current_user.company_id
    @sms_template.visibility = :service_channel if @sms_template.visibility.blank? && @sms_template.for_agent?
    @sms_template.save
    @service_channel = @sms_template.service_channel || ::ServiceChannel.find(params[:manager_template][:service_channel_id])
    set_common_variables
    @prefix = params[:sms_template][:prefix]
    if @sms_template.errors.empty?
      @status_message = { ok: true, text: I18n.t('service_channels.sms_template_saved') }
    else
      logger.info "Errors: #{@sms_template.errors.full_messages}" 
    end
    render :update_form
  end

  def destroy
    id = params[:id]
    @prefix = params[:prefix]
    if id.present?
      @sms_template    = ::SmsTemplate.find id
      @service_channel = @sms_template.service_channel
      templateKind     = @sms_template.kind
      if @sms_template.destroy
        @sms_template = ::SmsTemplate.new(kind: templateKind)
        @status_message = { ok: true, text: I18n.t('service_channels.sms_template_deleted') }
      end
    else
      @sms_template = ::SmsTemplate.new(kind: params[:kind])
      @service_channel = ::ServiceChannel.find params[:service_channel_id]
      @status_message = { ok: false, text: I18n.t('service_channels.cannot_delete_template') }
    end
    set_common_variables
    render :update_form
  end

  private

  def sms_template_params
    @sms_template_params ||= params[:sms_template].permit(:kind, :title, :text, :service_channel_id, :visibility, :location_id, :is_agent_console)
  end

  def load_sms_template
    id            = params[:sms_template][:id]
    @sms_template = id.present? && params[:sms_template][:save_as_new] != 'true' ? ::SmsTemplate.find(id) : ::SmsTemplate.new
    if params[:sms_template][:save_as_new] == 'false' && id.blank? && params[:sms_template][:title].present?
      @sms_template = ::SmsTemplate.where(title: params[:sms_template][:title])
                                   .where(
                                      params[:sms_template][:kind] == 'agent' ? 
                                        { service_channel_id: params[:sms_template][:service_channel_id] }
                                        : { company_id: current_user.company_id }
                                   ).first
    end
  end

  def set_common_variables
    if @sms_template.for_agent?
      @sms_templates        = @service_channel.agent_sms_templates
      gon.sms_templates     = @sms_templates
    else
      @manager_template     = @sms_template
      @manager_templates    = ::SmsTemplate.for_manager.accessible_by(current_ability)
      gon.manager_templates = @manager_templates
    end
  end

end
