class SipWidget < ActiveRecord::Base
  belongs_to :sip_settings

  def get_buttons
    buttons = []
    (1..6).each do |i|
      if (self.send("button_#{i}").present? && self.send("button_#{i}_extension").present?)
        buttons << {button_text: self.send("button_#{i}"), button_extension: self.send("button_#{i}_extension")}
      end
    end
    return buttons
  end

end
