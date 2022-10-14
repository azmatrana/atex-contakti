class MessageDecorator < ApplicationDecorator
  decorates_association :attachments

  def formatted_created_at
    object.created_at.strftime('%d.%m.%y %H:%M')
  end

  def formatted_description
    return '' if object.description.empty?
    object.description.gsub(/\n/, '<br/>').
      gsub(/ [+0-9]+(?:\.[0-9]*)?[0-9]{5,} /) { |m| "<a href='tel:#{m}'>#{m}</a>" }
  end

  def title
    title = object.title
    return title unless title.present?
    if object.channel_type == 'call'
      if object.task.data['caller_name']
        title += ", #{object.task.data['caller_name']}"
      end
    end
    title
  end

end
