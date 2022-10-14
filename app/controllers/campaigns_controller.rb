class CampaignsController < ApplicationController
  before_action :check_admin_access, except: [:search, :index]
  before_action :set_campaigns, only: [:index, :update, :search, :delete_all, :destroy, :upload_csv]

  def index
  end

  def search
    @campaigns = @campaigns.includes(:service_channel, :agents).ransack(
      m: 'or',
      name_cont: params[:search],
      service_channel_name_cont_any: params[:search],
      agent_last_name_cont_any: params[:search]
    ).result
  end

  def download_template
    header = 'FIRST-NAME;'
    header << 'LAST-NAME;'
    header << 'PHONENUMBER;'
    header << 'EMAIL;'
    header << 'ADDRESS;'
    header << 'POSTNUMBER;'
    header << 'CITY;'
    header << 'COUNTRY;'
    header << 'INFO-1;'
    header << 'INFO-2;'
    out_file = File.new("tmp/campaign_item_template_file.csv", "w")
    out_file.puts(header)
    out_file.close
    out_file = File.new("tmp/campaign_item_template_file.csv", "r")
    send_data out_file.read, filename: 'campaign_item_template_file.csv'
  end

  def upload_csv
    if params[:csv].blank?
      return render json: { errors:  I18n.t('errors.messages.csv_not_present') }, status: 400
    else
      errors = []

      campaign = @campaigns.new(name: "Campaign #{@campaigns.count + 1}")
      begin
        CSV.read(params[:csv].path, col_sep: ";", encoding: 'ISO8859-1' ).each_with_index do |row, index|
          next if index == 0
          attributes = {
            first_name: row[0],
            last_name: row[1],
            phone: row[2],
            email: row[3],
            address: row[4],
            postcode: row[5],
            city: row[6],
            country: row[7],
            info_1: row[8],
            info_2: row[9]
          }

          campaign_item = campaign.campaign_items.build(attributes)
        end
        unless campaign.save
          errors += campaign.errors.full_messages
        end

      rescue Exception => ex
        errors << ex.message
      end
    end

    unless errors.blank?
      render json: { errors:  errors }, status: 400
    else
      render nothing: true
    end
  end

  def update
    @campaign = @campaigns.where(id: params[:id]).first
    @campaign.assign_attributes(campaign_params)
  end

  def destroy
    @campaign = @campaigns.find(params[:id])
  end

  def delete_all
    @campaigns.destroy_all
    render :search
  end

  private

  def set_campaigns
    if current_user.has_role?(:agent)
      @campaigns = current_user.get_campaigns.includes(:service_channel, :agents).sort_by('name', :asc)
    else
      @campaigns = current_user.company.campaigns.includes(:service_channel, :agents).sort_by('name', :asc)
    end
  end

  def campaign_params
    params.require(:campaign).permit(
      :name,
      :service_channel_id,
      agent_ids: [],
    )
  end

end
