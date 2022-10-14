class SuperUi::CompaniesController < SuperadminApplicationController
  inherit_resources
  defaults resource_class: Company, route_instance_name: 'company', route_collection_name: 'companies', route_prefix: 'super_ui'

  def index
    @active_users_by_company, @active_last_month_by_company = ::ActiveAgentsService.current_and_last_month
    index!
  end

  def billing_params
    @billing_params ||= params.fetch(:q, { year: nil, month: nil}).permit(:year, :month)
  end

  def billing
    @year = billing_params[:year].presence.to_i
    @month = billing_params[:month].presence.to_i
    stats_chain = resource.stats
    if @year > 0
      stats_chain = stats_chain.where('EXTRACT(YEAR FROM date) = ?', @year)
    end
    if @month > 0
      stats_chain = stats_chain.where('EXTRACT(MONTH FROM date) = ?', @month)
    end
    @stats = stats_chain.order('date ASC').paginate(page: params[:page])
  end

  def activate
    @company = ::Company.find(params[:id])
    @company.activate! if @company
    redirect_to super_ui_companies_path
  end

  def deactivate
    @company = ::Company.find(params[:id])
    @company.deactivate! if @company
    redirect_to super_ui_companies_path
  end

  private

  def permitted_params
    params.permit!
  end
end
