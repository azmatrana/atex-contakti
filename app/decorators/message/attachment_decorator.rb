class Message::AttachmentDecorator < ApplicationDecorator
  delegate_all

  # Define presentation-specific methods here. Helpers are accessed through
  # `helpers` (aka `h`). You can override attributes, for example:
  #
  #   def created_at
  #     helpers.content_tag :span, class: 'time' do
  #       object.created_at.strftime("%a %m/%d/%y")
  #     end
  #   end

  def link
    ::Rails.application.routes.url_helpers.attachment_task_message_url(
      host: ::Settings.hostname,
      task_id: object.message.task_id,
      id: object.message_id,
      oid: object.file_before_type_cast
    )
  end
end
