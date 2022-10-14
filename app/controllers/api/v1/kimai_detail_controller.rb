class Api::V1::KimaiDetailController < Api::V1::BaseController

  before_action :set_kimai_detail

  def index_kimai_detail
    @kimai_details = Kimai::KimaiDetail.all
  end

  def create_kimai_detail
    @kimai_details = Kimai::KimaiDetail.new(kimai_params)
    @kimai_details.company_id = current_user.company.id
    @kimai_details.user_id = current_user.id
    if @kimai_details.save
    else
      render :json => { :errors => @kimai_details.errors.full_messages }
    end
  end

  private
  def kimai_params
    params.require(:kimai_detail).permit(:tracker_email, :tracker_auth_token, :company_id, :user_id)
  end

  def set_kimai_detail
    @kimai_details = Kimai::KimaiDetail.new
  end
end