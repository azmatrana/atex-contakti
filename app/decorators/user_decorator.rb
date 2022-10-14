class UserDecorator < ApplicationDecorator

  # Define presentation-specific methods here. Helpers are accessed through
  # `helpers` (aka `h`). You can override attributes, for example:
  #
  #   def created_at
  #     helpers.content_tag :span, class: 'time' do
  #       object.created_at.strftime("%a %m/%d/%y")
  #     end
  #   end
  def full_name
    "#{object.first_name} #{object.last_name}"
  end

  def full_info_table
    html = <<-HTML
      <table>
        <tr>
          <td>#{full_name}</td>
          <td>#{email}</td>
          <td>#{mobile}</td>
        </tr>
      </table>
    HTML
    html.html_safe
  end

end
