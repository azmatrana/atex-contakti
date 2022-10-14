class VatsController < ApplicationController
  before_action :set_company

  def create
    @vat = @current_company.vats.new(vat_params)
    if @vat.save
      render json: { data: @vat.as_json, success: t('vats.create_success')}
    else
      render :json => { :errors => @vat.errors.full_messages }
    end
  end
  
  def update
    @vat = @current_company.vats.find_by_id(params[:id])
    if @vat.update(vat_params)
      render json: { data: @vat.as_json, success: t('vats.update_success')}
    else
      render :json => { :errors => @vat.errors.full_messages }
    end
  end

  def destroy
    @vat = @current_company.vats.find_by_id(params[:id])
    if @vat.destroy
      render json: { success: t('vats.delete_success')}
    else
      render json:{ :errors => @vat.errors.full_messages}
    end
  end
  

  private

  def vat_params
    params.require(:vat).permit(:vat_percentage)
  end

  def set_company
    @current_company = @current_user.company
  end
  
end
