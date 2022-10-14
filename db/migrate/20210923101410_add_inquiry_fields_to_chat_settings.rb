class AddInquiryFieldsToChatSettings < ActiveRecord::Migration
  def change
    ServiceChannel.all.each do |service_channel|
      titles = ["Name", "Email", "Phone"]
      titles.each do |title|
        service_channel.chat_media_channel.chat_settings.chat_inquiry_fields.create(title: title) rescue nil
      end
    end
  end
end
