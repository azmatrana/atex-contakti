# == Schema Information
#
# Table name: dashboard_layouts
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  size_x            :integer
#  size_y            :integer
#  company_id        :integer
#  default           :boolean
#  created_at        :datetime
#  updated_at        :datetime
#  layout            :text
#  dashboard_default :boolean          default(FALSE)
#  report_default    :boolean          default(FALSE)
#

class DashboardLayout < ActiveRecord::Base
  serialize :layout, Array
  WIDGETS = %w(
    call_channel_stats
    email_stats
    calls_stats
    web_form_stats
    chat_channel_stats
    internal_stats
    media_channels_stats
    peak_times
    tasks_by_location
    tasks_by_service_channel
    tasks_counter
    pauses
    solutions
    solved_tasks
    turnaround
    chat
    sla
    sms_stats
    chatbot_stats
  )
  DEFAULT_SIZE_X = 3
  DEFAULT_SIZE_Y = 3

  before_save :update_defaults

  validates_presence_of :name
  validates_presence_of :layout

  def self.default_for(company, type)
    _type = type.to_s
    layout = self.where(company_id: company.id, "#{_type}_default" => true).first ||
        self.where(company_id: company.id, default: true).first ||
        self.where("#{_type}_default" => true, company_id: nil).first ||
        self.where(default: true, company_id: nil).first

    if !layout
      layout = predefined_for(company, type)
    end

    layout
  end

  def self.predefined_for(company, type)
    layout = self.new
    layout.layout = [
      {"col"=>1, "row"=>1, "size_x"=>1, "size_y"=>1, "name"=>"email_stats"},
      {"col"=>2, "row"=>1, "size_x"=>1, "size_y"=>1, "name"=>"web_form_stats"},
      {"col"=>3, "row"=>1, "size_x"=>1, "size_y"=>1, "name"=>"chatbot_stats"},
      {"col"=>4, "row"=>1, "size_x"=>1, "size_y"=>1, "name"=>"chat_channel_stats"},
      {"col"=>1, "row"=>2, "size_x"=>1, "size_y"=>1, "name"=>"sms_stats"},
      {"col"=>2, "row"=>2, "size_x"=>1, "size_y"=>1, "name"=>"internal_stats"},
      {"col"=>3, "row"=>2, "size_x"=>1, "size_y"=>1, "name"=>"calls_stats"},
      {"col"=>4, "row"=>3, "size_x"=>1, "size_y"=>1, "name"=>"tasks_counter"},
      {"col"=>1, "row"=>3, "size_x"=>2, "size_y"=>1, "name"=>"peak_times"},
      {"col"=>4, "row"=>2, "size_x"=>1, "size_y"=>1, "name"=>"call_channel_stats"},
      {"col"=>3, "row"=>3, "size_x"=>1, "size_y"=>1, "name"=>"sla"},
      {"col"=>1, "row"=>4, "size_x"=>2, "size_y"=>1, "name"=>"tasks_by_location"},
      {"col"=>3, "row"=>4, "size_x"=>2, "size_y"=>1, "name"=>"tasks_by_service_channel"}
    ]

    layout.name = I18n.t('reports.summary_report.default')
    layout.size_x = 3
    layout.size_y = 3
    layout.dashboard_default = true
    layout
  end

  def update_defaults
    if !!default
      defaults = self.class.where(company_id: self.company_id, default: true).where.not(id: self.id)
      defaults.update_all(default: false) if defaults.presence
    end
    if !!dashboard_default
      dashboard_defaults = self.class.where(company_id: self.company_id, dashboard_default: true).where.not(id: self.id)
      dashboard_defaults.update_all(dashboard_default: false) if dashboard_defaults.presence
    end
    if !!report_default
      report_defaults = self.class.where(company_id: self.company_id, report_default: true).where.not(id: self.id)
      report_defaults.update_all(report_default: false) if report_defaults.presence
    end
  end
end
