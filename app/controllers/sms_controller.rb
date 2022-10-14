class SmsController < ApplicationController

  def create
    service_channel = ServiceChannel.find params['service_channel_id']
    sms_media_channel = service_channel.sms_media_channel
    if service_channel.sms_media_channel.sms_sender.blank?
      return render json: { errors:  I18n.t('errors.messages.sms_sender') }, status: 400
    elsif params[:csv].blank?
      return render json: { errors:  I18n.t('errors.messages.csv_not_present') }, status: 500
    end    
    SmsMultiSenderWorker.perform_async(
      collect_phone_numbers,
      params[:message],
      create_tasks: params[:create_tasks],
      service_channel_id: params[:service_channel_id]
    )
    render nothing: true
  end

  private

  def collect_phone_numbers
    CSV.read(params[:csv].path).map do |row|
      phonelib_obj = Phonelib.parse row[0]
      if phonelib_obj.valid?
        phonelib_obj.full_e164
      else
        nil
      end
    end.compact
  end
end
