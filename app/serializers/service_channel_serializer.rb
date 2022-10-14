class ServiceChannelSerializer < ActiveModel::Serializer
  attributes *ServiceChannel.attribute_names.map(&:to_sym), :agent_sms_templates, :agents, :has_valid_email

  def agents
    [{id: nil, name: I18n.t('activerecord.models.task.association_types.open_to_all'), online: false, working: false}] + object.users.map do |user|
      {
        id: user.id,
        name: "#{user.first_name} #{user.last_name}",
        online: user.is_online,
        working: user.is_working
      }
    end
  end

  def has_valid_email
    object.agent_private? ?
      (object.owner_user.try(:smtp_settings).present? &&
         object.owner_user.try(:imap_settings).try(:from).present?) :
      # check next code -> 
      (object.email_media_channel.present? &&
        object.email_media_channel.smtp_settings.present? &&
        object.email_media_channel.active? &&
        object.email_media_channel.imap_settings.present? &&
        object.email_media_channel.imap_settings.from.present?)
  end
end
