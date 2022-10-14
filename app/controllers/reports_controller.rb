class ReportsController < ApplicationController
#  skip_before_filter :set_switchable_users, :allow_super_admin!, :verify_authenticity_token, :authenticate_user!, :authenticate_user_from_token!, :update_current_session, :check_admin_access, :if => proc { ScreenshotGenerator::secure_token_valid?(params[:token]) }
#  before_action :check_admin_access, :unless => proc { ScreenshotGenerator::secure_token_valid?(params[:token]) }

  skip_before_filter :verify_authenticity_token, :allow_super_admin!, :authenticate_user_from_token!, :authenticate_user!, :update_current_session, :set_switchable_users, :if => proc { ScreenshotGenerator::secure_token_valid?(params[:token]) }

  before_action :load_report, except: [:dashboard, :search]

  layout Proc.new { action_name.starts_with?('print') ? 'print' : 'application' }

  def dashboard
    @report = ::Report.new(kind: 'summary', company_id: current_user.company_id, show_all: true)
    @report.is_for_dashboard! # (CON-126) Dirty fix to differentiate between a generated report (which should show solved tasks as well) & dashboard
    @layout = ::DashboardLayout.default_for(current_user.company, :dashboard)
    @layouts = ::DashboardLayout.accessible_by(current_ability)
    @layouts.unshift ::DashboardLayout.predefined_for(current_user.company, :dashboard)
    @is_for_dashboard = true

    startDate = params[:startDate]
    endDate = params[:endDate]

    if startDate.nil? or endDate.nil?
      startDate = Date.today.beginning_of_day
      endDate = Date.today.end_of_day
    else
      startDate = Date.parse(startDate).beginning_of_day
      endDate = Date.parse(endDate).end_of_day
    end

    @report.starts_at = startDate
    @report.ends_at = endDate

    # @data = @report.get_data
    @data = @report.get_data(current_user)

    startRange = startDate.strftime('%d/%m/%Y')
    endRange = endDate.strftime('%d/%m/%Y')

    if startRange == endRange
      @range = startRange
    else
      @range = startRange + " - " + endRange
    end
  end

  def index
    set_common_variables
    @layouts = ::DashboardLayout.accessible_by(current_ability)
    @layouts.unshift ::DashboardLayout.predefined_for(current_user.company, :report)
  end

  def new
    set_common_variables
    @show_form = true
    render :index
  end

  def edit
    set_common_variables
    @data = @report.get_data
    @layout = @report.dashboard_layout || ::DashboardLayout.default_for(current_user.company, :report)
    @show_form = true
  end

  def search
    index
  end

  def save
    set_common_variables
    @report.attributes = report_params
    @report.company_id = current_user.company_id
    @report.save if @report.persisted? && @report.changed?
    @layout = @report.dashboard_layout
    if @report.valid?
      @data = @report.get_data
      render action: @report.kind
    else
      logger.info "Report errors: #{@report.errors.inspect}"
      set_common_variables
      @show_form = true
      render :index
    end
  end

  def update
    @report.attributes = report_params
    @report.company_id = current_user.company_id
    @report.author_id = current_user.id
    if @report.send_to_emails.blank? && @report.scheduled.present?
      @report.errors.add(:send_to_emails, :empty)
      @data = @report.get_data
      render :action => @report.kind
    else
      @report.save!
      flash[:notice] = I18n.t('reports.comparison.report_updated')
      redirect_to show_report_path(@report.id)
    end
  end

  def show
    @data = @report.get_data
    @layout = @report.dashboard_layout || ::DashboardLayout.default_for(current_user.company, :report)
    render :action => @report.kind
  end

  def show_preview
    @data = @report.get_data
    @layout = @report.dashboard_layout || ::DashboardLayout.default_for(current_user.company, :report)
    @preview = true
    case @report.kind
      when 'comparison'
        render :partial => 'preview_comparison_data'
      else
        render :partial => 'preview_summary_data'
    end
  end

  def destroy
    notice = I18n.t("reports.index.#{@report.destroy ? 'deleted_report' : 'cannot_delete_report'}")
    redirect_to reports_url, notice: notice
  end

  def print
    logger.info "Params are.........#{params.inspect}"
    logger.info "Old Locale--------------#{I18n.locale}"
    @is_email = params[:email] == 'true'
    @layout = @report.dashboard_layout || ::DashboardLayout.default_for(@report.company, :report)
    if params[:start_date] && params[:end_date]
      @report.starts_at = ::DateTime.parse(params[:start_date])
      @report.ends_at   = ::DateTime.parse(params[:end_date])
    end
    @data = @report.get_data
    render :action => "print_#{@report.kind}"
  end

  def send_report
    @report.send_to_emails = params[:send_to_emails]
    if @report.send_to_emails.blank?
      @report.errors.add(:send_to_emails, :empty)
    else
      @report.save if @report.changed?
      options = { locale: params["locale"] }
      logger.info "=============options=======#{options.inspect}"
      ::SendReportWorker.perform_async(params[:id], { locale: params["locale"] })
      flash[:notice] = I18n.t('reports.comparison.report_sent')
    end
  end

  private

  def set_common_variables
    @q = ::Report.accessible_by(current_ability).ransack(get_ransack_query('query_reports'))
    @q.sorts = 'created_at desc' if @q.sorts.empty?
    @layouts = ::DashboardLayout.accessible_by(current_ability)
    @reports = @q.result(distinct: false)
    @locations = ::Location.accessible_by(current_ability)
    @service_channels = ::ServiceChannel.joins(:locations).includes(:locations, :email_media_channel, :web_form_media_channel, :call_media_channel, :internal_media_channel)
                                        .accessible_by(current_ability)
    @agents = ::User.with_role(:agent).for_company(current_user.company_id).decorate
  end

  def load_report
    @report = params[:id] ? ::Report.find(params[:id]) : ::Report.new
    authorize!(:read, @report) if @report.persisted? unless ScreenshotGenerator.secure_token_valid?(params[:token])
  end

  def report_params
    @report_params ||= params[:report].permit(
      :kind,
      :title,
      :starts_at,
      :ends_at,
      :send_to_emails,
      :scheduled,
      :start_sending_at,
      :date_range,
      :report_scope,
      :dashboard_layout_id,
      :locale,
      user_ids: [],
      location_ids: [],
      service_channel_ids: [],
      media_channel_types: []
    )
  end
end
