class Api::V1::AgentCallLogsController < Api::V1::BaseController

  before_action :check_agent_access
  before_action :set_logs
  before_action :load_call_by_id, only: [:update]
  before_action :set_call_source, only: [:create]

  def danthes_subscribe
    channel = "/agent_call_logs/#{current_user.id}"
    render json: ::Danthes.subscription(channel: channel)
  end

  def index
    @call_logs = @call_logs.visible
    render json: @call_logs.as_json
  end

  def user_call_settings
    if params[:lastAction].present?
      current_user.toggle_agent_call_settings(params[:lastAction])
    end
    render json: current_user.as_json(only: [:is_dnd_active, :is_transfer_active, :is_acd_active, :is_follow_active]), status: :ok
  end

  def create
    call = @call_logs.new
    call = @call_logs.find_or_initialize_by(sip_id: call_params[:id])

    call.call_status = call_params[:status]
    call.caller_name = call_params[:caller_name]
    call.uri         = call_params[:uri]
    call.flow        = call_params[:flow]
    call.sip_id      = call_params[:id]
    call.clid        = call_params[:clid]
    call.call_start  = call_params[:start]
    call.call_stop   = call_params[:stop]

    if call.new_record? && call.call_status == 'ringing'
      call.call_ring_start = Time.now.to_i
    elsif call.persisted? && call.call_status == 'answered'
      call.call_ring_stop = Time.now.to_i
    end

    if @source.present?
      call.callable_id   = @source.id
      call.callable_type = @source.class.name
    end

    fonnecta_data = {}

    begin
      phone_to_search = ::Fonnecta::Contacts.conver_text_to_phone(call.clid)
      if call.caller_name.blank?
        fonnecta_cache = ::Fonnecta::Contacts.new(current_user.company, phone_to_search).search_full_data
        caller_name = call.caller_name || fonnecta_cache.full_name

        fonnecta_data = fonnecta_cache.as_json
        is_group_caller = call.clid.index(':')
        if is_group_caller
          call.caller_name = call.clid[0..is_group_caller] + caller_name
        else
          call.caller_name = caller_name
        end
      else
        fonnecta_data ::Fonnecta::ContactCache.where(phone_number: phone_to_search, company: @company).first
      end
    rescue

    end


    if call.save
      render json: call.as_json.merge({
        fonnecta_data: fonnecta_data
      }), status: :ok
    else
      render json: { message: call.errors.full_messages }, status: 400
    end
  end

  def update
    @call.assign_attributes(call_params)
    @call.call_start = call_params[:start]
    @call.call_stop  = call_params[:stop]
    @call.call_status = call_params[:status]

    # @call.clid        = "00987656789"

    if @call.save
      render json: @call.as_json, status: :ok
    else
      render json: { message: @call.errors.full_messages }, status: 400
    end
  end

  def destroy_all
    @call_logs.update_all(visible: false)
    AgentCallLog.push_to_browser(current_user.id)
    render nothing: true
  end

  private

  def set_call_source
    if params[:source_type].present? && params[:source_id].present?
      if params[:source_type] === 'campaign_item'
        campaign_item = CampaignItem.find_by_id(params[:source_id])
        if (campaign_item && current_user.get_campaigns.include?(campaign_item.campaign))
          @source = campaign_item
        end
      end
    end
  end

  def load_call_by_id
    @call = @call_logs.find_by_id(params[:id])
  end

  def set_logs
    @call_logs = current_user.agent_call_logs
  end

  def call_params
    @call_params ||= params.permit(
        :caller_name,
        :clid,
        :flow,
        :id,
        :status,
        :start,
        :stop,
        :uri
    )
  end
end
