class Api::V1::CustomersController < Api::V1::BaseController

    skip_before_filter :authenticate_user!
    skip_before_filter :authenticate_user_from_token!

    def create
      @customer = Chatbot::Customer.new(customer_params)
      if @customer.save
        render json: @customer, ok: true
      else
        render json: {errors: @customer.errors.messages}, ok: false
      end
    end
    

    private
    def customer_params
      params.require(:customer).permit(
        :full_name,
        :email,
        :phone_number,
        :street_address,
        :city,
        :zip_code
      )
    end
  end

