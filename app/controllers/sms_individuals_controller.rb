class SmsIndividualsController < ApplicationController
  include TasksHelper
  def create
    flag = 0
    service_channel = ServiceChannel.find(params[:service_channel_id])
    sms_media_channel = service_channel.sms_media_channel
    if service_channel.sms_media_channel.sms_sender.blank?
      return render json: { errors:  I18n.t('errors.messages.sms_sender') }, status: 400
    end
    params[:reply][:to].split(", ").each do |reply_to|
      SmsSenderWorker.perform_async(
          service_channel.sms_media_channel.sms_sender,
          reply_to,
          params[:message],
          service_channel.company_id
      ) if service_channel.company.sms_provider
      new_task = sms_media_channel.add_sms_task(service_channel.sms_media_channel.sms_sender, reply_to, params[:message])
      if params[:reply][:is_sms].present?
        new_task.send_by_user = current_user;
      end
      if new_task.save
        flag = 0
        wit_response = post_to_wit_api(new_task)
        new_task.save
      else
        flag = 1
      end
    end
    if flag == 0
      render nothing: true
    else
      render json: { errors: new_task.errors.full_messages }, status: 422
    end
  end
end
