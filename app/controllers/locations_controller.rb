class LocationsController < ApplicationController
  before_action :check_admin_access
  before_action :set_common_variables
  before_action :create_or_update_location, only: [:create, :update]

  def index
  end

  def new
    @show_form = true
    render :index
  end

  def show
    render :index
  end

  def search
  end

  def create
  end

  def update
  end

  def destroy
    notice = if @location.destroy
               'Destroyed agent'
             else
               'Cannot destroy agent'
             end
    redirect_to locations_path, notice: notice
  end

  private

  def create_or_update_location
    @location.attributes = location_params
    @location.company_id = current_user.company_id unless @location.persisted?
    if @location.save
      flash[:notice] = I18n.t('locations.location_saved')
      redirect_to location_path(@location)
    else
      @show_form = true
      render :index
    end
  end

  def location_params
    @location_params ||= params.require(:location).
      permit(:name, :street_address, :zip_code, :city, user_ids: [], manager_ids: [], service_channel_ids: [],
             weekly_schedule_attributes: [:open_full_time, schedule_entries_attributes: [:start_time, :end_time, :_destroy, :weekday]])
  end

  def set_common_variables
    @q = ::Location.accessible_by(current_ability).ransack(get_ransack_query('query_locations'))
    @q.sorts = 'name asc' if @q.sorts.empty?
    @locations = @q.result(distinct: true)
    @agents    = ::User.with_role(:agent).accessible_by(current_ability).decorate
    @managers  = ::User.with_role(:admin).accessible_by(current_ability).decorate
    @service_channels = ::ServiceChannel.shared.accessible_by(current_ability)
    @location  = params[:id] ? ::Location.find(params[:id]) : ::Location.new
    @location.weekly_schedule ||= WeeklySchedule.new
    authorize!(:read, @location) if @location.persisted?
  end
end
