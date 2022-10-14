class CallDetailRecordsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :authenticate_user!, :update_current_session, only: [:create, :create_from_json]

  def create
    logger.info "Inspecting raw POST data: #{request.raw_post}"
    doc = ::Nokogiri::XML(request.raw_post)
    call_records = ::MediaChannel::Call.parse_call_detail_xml(doc)
    call_records.each do |call_data|
      ::MediaChannel::Call.where(group_id: call_data[:group_id], deleted_at: nil).each do |media_channel|
        # TODO push to queue to avoid task.messages.count + 1 issue
        if media_channel.group_id.present? && media_channel.try(:service_channel).try(:company)
          begin
            media_channel.add_task_from_hash(call_data)
          rescue StandardError => e
            logger.info "Something wrong with media_channel: #{media_channel.id}"
            logger.info "#{e.message}"
          end
        end
      end
    end
    render nothing: true
  end

  def create_from_json
    logger.info "Callback task (JSON): #{request.raw_post}"
    doc = ::Oj.load(request.raw_post)
    logger.info "Parsed task: #{doc.to_yaml}"

    MediaChannel::Call.where(group_id: doc['variables']['destination']).each do |media_channel|
      if media_channel.group_id.present?
        media_channel.add_task_from_json_message(doc)
      end
    end

    render nothing: true
  end

end
