class ShipmentMethodsController < ApplicationController
    before_action :set_company

    def index
      render json: @current_company.shipment_methods
    end

    def create
      @shipment_method = @current_company.shipment_methods.new(shipment_method_params)
      if @shipment_method.save
        render json: { data: @shipment_method , success: t('shipment_methods.create_success')}
      else
        render json:{ :errors => @shipment_method.errors.full_messages}
      end
    end

    def update
      @shipment_method = @current_company.shipment_methods.find_by_id(params[:id])
      if @shipment_method.update(shipment_method_params)
        render json: { data: @shipment_method , success: t('shipment_methods.update_success')}
      else
        render json:{ :errors => @shipment_method.errors.full_messages}
      end
    end

    def destroy
      @shipment_method = @current_company.shipment_methods.find(params[:id])
      if @shipment_method.destroy
        render json: { data: @shipment_method , success: t('shipment_methods.delete_success')}
      else
        render json:{ :errors => @shipment_method.errors.full_messages}
      end
    end

    private

    def shipment_method_params
      params.require(:shipment_method).permit(
        :name,
        :price
      )
    end

    def set_company
      @current_company = current_user.company
    end
  end