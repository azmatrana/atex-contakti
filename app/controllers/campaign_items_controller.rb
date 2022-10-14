class CampaignItemsController < ApplicationController
  # before_action :check_admin_access, except: [:search, :index, :danthes_subscribe, :show, :update, :destroy]
  before_action :check_admin_access, only: [:destroy, :delete_all]
  before_action :set_campaign, only: [:danthes_subscribe]
  before_action :set_campaign_items, only: [:danthes_subscribe, :index, :update, :search, :delete_all, :destroy, :upload_csv, :show]

  def index
  end

  def danthes_subscribe
    channel = "/campaign_items/#{@campaign.id}"
    render json: ::Danthes.subscription(channel: channel)
  end

  def show
    @campaign_item = @campaign_items.find_by_id(params[:id])
  end

  def search
    @campaign_items = @campaign_items.ransack(
      m: 'or',
      first_name_cont: params[:search],
      last_name_cont: params[:search],
      phone_cont: params[:search],
      email_cont: params[:search],
      address_cont: params[:search],
      city_cont: params[:search],
      country_cont: params[:search],
      postcode_cont: params[:search],
      info_1_cont: params[:search],
      info_2_cont: params[:search]
    ).result
  end

  def update
    @campaign_item = @campaign_items.where(id: params[:id]).first
    @campaign_item.assign_attributes(campaign_item_params)
  end

  def destroy
    @campaign_item = @campaign_items.find(params[:id])
  end

  def delete_all
    @campaign_items.destroy_all
    render :search
  end

  private

  def set_campaign
    @campaign = current_user.company.campaigns.find_by_id(params[:campaign_id])
  end

  def set_campaign_items
    @campaign = current_user.company.campaigns.find_by_id(params[:campaign_id])
    if @campaign.present?
      @campaign_items = @campaign.campaign_items.includes(:agent_call_logs, :task).sort_by('last_name', :asc)
      if @is_agent
        @campaign_items = @campaign_items.without_task
      end
    end
  end

  def campaign_item_params
    params.require(:campaign_item).permit(
      :first_name,
      :last_name,
      :phone,
      :email,
      :address,
      :city,
      :country,
      :postcode,
      :info_1,
      :info_2
    )
  end

end
