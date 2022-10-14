class DashboardLayoutsController < ApplicationController
  before_action :check_admin_access
  before_action :load_dashboard_layout, except: [ :index, :create ]

  def index
    @q = ::DashboardLayout.accessible_by(current_ability).ransack(get_ransack_query('query_layouts'))
    @q.sorts = 'created_at desc' if @q.sorts.empty?
    @layouts = @q.result(distinct: false)
    render json: @layouts 
  end

  def show
    render json: @layout
  end

  def create
    @layout = DashboardLayout.new
    set
    if @layout.save
      return render json: @layout, status: 201
    else
      return render json: {errors: @layouts.errors}, status: 400
    end
  end

  def update
    if params[:id] == 'default'
      DashboardLayout.all.each do |d|
        d.dashboard_default = false
        d.save
      end
      return render json: {}, status: 200
    end

    @layout = DashboardLayout.find params[:id]
    set
    if @layout.save
      return render json: @layout, status: 200
    else
      return render json: {errors: @layout.errors}, status: 400
    end
  end

  def destroy
   @layout.destroy
   return render json: {}, status: 200
  end

  def default
    @layout = ::DashboardLayout.default_for(current_user.company, :dashboard)
    render json: @layout
  end

  private
  def set
    @layout.attributes = dashboard_layout_params
    @layout.company_id = current_user.company_id
    @layout.layout = JSON.parse(@layout.layout) if @layout.layout and @layout.layout.is_a? String
    @layout.size_x = ::DashboardLayout::DEFAULT_SIZE_X
    @layout.size_y = ::DashboardLayout::DEFAULT_SIZE_Y
  end

  def dashboard_layout_params
    @layout_params ||= params[:dashboard_layout].permit(
        :layout, :company_id, :size_x, :size_y, :default, :name, :dashboard_default, :report_default
    )
  end

  def load_dashboard_layout
    @layout = (params[:id] && params[:id] != 'default') ? ::DashboardLayout.find(params[:id]) : ::DashboardLayout.new
    if action_name == 'edit'
      authorize!(:read, @layout)
    elsif @layout.persisted?
      authorize!(:manage, @layout)
    end
  end
end
