class Api::V1::OrdersController < Api::V1::BaseController

    skip_before_filter :authenticate_user!
    skip_before_filter :authenticate_user_from_token!

    def create
      @order = Chatbot::Order.new
      @media_channel = MediaChannel::Chat.find(params[:service_channel_id])
      @company = @media_channel.company
      @order.company_id = @company.id
      @order.service_channel_id = @media_channel.service_channel_id
      @order.inquiry_fields_data = params[:inquiry_fields_data].to_json
      @order.preferred_language = I18n.locale
      @order.attributes = order_params
      @order.shipment_price = @order.shipment_method.price

      if @order.save
        render json: { data: @order.as_json}
      else
        render :json => { :errors => @order.errors.full_messages }
      end
    end

    def show
      @order = Chatbot::Order.find_by_id(params[:id])
      render json: @order.as_json(:methods => [:chat_inquiry_fields_json, :price_without_taxes, :taxes], :include => {
        customer: {},
        shipment_method: { only: :name },
        order_products: {:only => [:quantity, :order_products, :price, :with_vat, :vat_percentage, :currency], methods: [:actual_price, :tax_amount], include: :product},
        chatbot_paytrail_payment: { :only => [:status, :payment_time]}
        })
    end

    private
    def order_params
      params.require(:order).permit(
        :checkout_method,
        :task_id,
        :currency,
        :shipment_price,
        :total,
        :inquiry_fields_data,
        :shipment_method_id,
        :customer_id,
        order_products_attributes: [
          :id,
          :chatbot_product_id,
          :quantity,
          :currency,
          :price,
          :with_vat,
          :vat_percentage,
        ]
      )
    end
  end

