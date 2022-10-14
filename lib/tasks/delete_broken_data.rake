desc "Delete broken data in db"

task :delete_broken_data => :environment do
  ::ServiceChannel.joins(
    'LEFT JOIN companies ON service_channels.company_id = companies.id AND companies.id IS NULL'
  ).joins(
    'LEFT JOIN users ON service_channels.id = users.service_channel_id AND users.service_channel_id IS NULL'
  ).includes(:company, :user).find_each do |service_channel|
    next if service_channel.company || service_channel.user
    p service_channel
    p "tasks count: #{service_channel.tasks.count}"
    service_channel.tasks.includes(messages: [:attachments]).find_each do |task|
      task.messages.each do |message|
        message.attachments.each do |attachment|
          attachment.really_destroy!
        end
        message.really_destroy!
      end
      task.really_destroy!
    end
    p "media channels count: #{service_channel.media_channels.count}"
    service_channel.media_channels.each do |media_channel|
      media_channel.really_destroy!
    end
    service_channel.really_destroy!
  end

  ::MediaChannel.joins(
    'LEFT JOIN service_channels ON media_channels.service_channel_id = service_channels.id AND service_channels.id IS NULL'
  ).find_each do |media_channel|
    p media_channel
    p "tasks count: #{media_channel.tasks.count}"
    media_channel.tasks.includes(messages: [:attachments]).find_each do |task|
      task.messages.each do |message|
        message.attachments.each do |attachment|
          attachment.really_destroy!
        end
        message.really_destroy!
      end
      task.really_destroy!
    end
    media_channel.really_destroy!
  end

  # ::User.joins(
  #   'LEFT JOIN companies ON users.company_id = companies.id AND companies.id IS NULL'
  # ).find_each do |user|
  #   p user
  #   user.destroy
  # end

  ::ChatSettings.joins(
    'LEFT JOIN media_channels ON chat_settings.id = media_channels.chat_settings_id AND media_channels.chat_settings_id IS NULL'
  ).find_each do |chat_settings|
    p chat_settings
    chat_settings.destroy
  end
end
