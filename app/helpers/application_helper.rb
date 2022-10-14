module ApplicationHelper
  MAJOR = 0
  MINOR = 9
  PATCH = 5
  COMMIT = if ::File.exist?(::Rails.root.join('REVISION').to_s)
             ::File.read(::Rails.root.join('REVISION').to_s)
           else
             `git --git-dir="#{Rails.root.join(".git")}" --work-tree="#{Rails.root}" log -1 --date=short --format="%ad-%h"|sed 's/-/./g'`
           end

  def print_version
    "#{MAJOR}.#{MINOR}.#{PATCH}.#{COMMIT}"
  end

  def self.print_version
    "#{MAJOR}.#{MINOR}.#{PATCH}.#{COMMIT.gsub(/\n/, '')}"
  end

  def display_base_errors resource
    return '' if (resource.errors.empty?) or (resource.errors[:base].empty?)
    messages = resource.errors[:base].map {|msg| content_tag(:p, msg)}.join
    html = <<-HTML
    <div class="alert alert-error alert-block">
      <button type="button" class="close" data-dismiss="alert">&#215;</button>
      #{messages}
    </div>
    HTML
    html.html_safe
  end

  def json_for(target, options = {})
    options[:scope] ||= self
    options[:url_options] ||= url_options
    serializer = options[:serializer] || target.active_model_serializer
    serializer.new(target, options).to_json
  end

  def nav_pil_link(label, link, remote = false)
    li_class = (link == request.url) ? 'disabled' : ''
    content_tag :li, class: li_class do
      link_to label, link, class: 'btn btn-primary', remote: remote
    end
  end

  def get_selected_class(item)
    'selected' if item.id.to_s == params[:id]
  end

  def home_page_link_url
    if current_user.has_role?('admin')
      main_dashboard_url
    else
      root_url
    end
  end

  def weekly_schedule_head(entries, form)
    ->(dates) {
      content_tag(:thead) do
        content_tag(:tr) do
          capture do
            dates.each do |date|
              wday_in_entries = date.wday == 0 ? 7 : date.wday
              concat(
                content_tag(:th) do
                  content_tag(:div, class: 'checkbox') do
                    content_tag(:label, class: 'checkbox-custom') do
                      check_box_tag(
                        'enable',
                        date.wday,
                        entries[wday_in_entries].present? && entries[wday_in_entries].any? {|e| e.start_time},
                        class: 'toggle-schedule-entries'
                      ) +
                        '<i class="fa fa-fw fa-square-o checked"></i>'.html_safe +
                        I18n.t("date.abbr_day_names")[date.wday]
                    end
                  end
                end
              )
            end
          end
        end
      end
    }
  end

  def weekly_schedule_options(entries = [], editable = false, form = nil)
    opts = {
      table: {class: "table table-bordered"},
      tr: {class: "calendar-row"},
      td: {class: "day"},
      number_of_weeks: 1,
      title: '',
      previous_link: '',
      next_link: '',
      events: entries
    }
    opts[:thead] = weekly_schedule_head(entries.group_by {|e| e.weekday}, form) if editable
    opts
  end

  def current_translations
    @translations ||= I18n.backend.send(:translations)
    @translations[I18n.locale].with_indifferent_access
  end

  def users_details?
    controller.controller_name == 'users' && controller.action_name == 'details'
  end

  def get_priority_expire_time(tag)
    value = Priority.find_by(company_id: current_user.company, tag_id: tag )
    value ? value.expire_time : 0
  end

  def get_skill_priority_class(priority)
    return 'priority-no' if priority.blank?

    case priority.priority_value
      when 0
        return 'priority-0'
      when 1
        return 'priority-1'
      when 2
        return 'priority-2'
      when 3
        return 'priority-3'
      else
        return 'priority-no'
      end
  end

end
