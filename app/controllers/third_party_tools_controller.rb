class ThirdPartyToolsController < ApplicationController
  before_action :set_company, only: [:create, :update, :destroy, :index]

  def index
    render json:  @current_company.third_party_tools.order(created_at: :desc)
  end

  def create
    @tool = @current_company.third_party_tools.new(third_party_tools_params)
    if @tool.save
      render :json => { data: @tool, success: t('user_dashboard.third_party_tools.create_success') }
    else
      render :json => { :errors => @tool.errors.full_messages }
    end
  end

  def update
    @tool = @current_company.third_party_tools.find_by_id(params[:id])
    @tool.assign_attributes(third_party_tools_params);
    if @tool.save
      render :json => { data: @tool, success: t('user_dashboard.third_party_tools.update_success') }
    else
      render :json => { :errors => @tool.errors.full_messages }
    end
  end

  def destroy
    @tool = @current_company.third_party_tools.find_by_id(params[:id])
    if @tool.destroy
      render :json => { success: t('user_dashboard.third_party_tools.delete_success') }
    else
      render :json => { :errors => @tool.errors.full_messages }
    end

  end

  private

  def third_party_tools_params
    params.require(:third_party_tool).permit(:title, :content)
  end

  def set_company
    @current_company = current_user.company
  end
end
