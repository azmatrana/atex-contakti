class CustomersController < ApplicationController
  def show
    render json: Customer.find(params[:id])
  end

  def create
    @customer = Customer.new(customer_params.merge({company_id: current_user.company_id}))
    if @customer.save
      render json: @customer
    else
      render json: {errors: @customer.errors}, status: :unprocessable_entity
    end
  end

  def update
    @customer = Customer.where(company_id: current_user.company_id, id: params[:id]).first
    if @customer.update(customer_params)
      render json: @customer
    else
      render json: {errors: @customer.errors}, status: :unprocessable_entity
    end
  end

  def destroy
    @customer = Customer.find(params[:id])
    if @customer
      @customer.destroy
      render json: {}, status: 200
    else
      render json: {errors: @customer.errors}, status: :unprocessable_entity
    end
  end

  def update_task_note
    @customer = Customer.where(company_id: current_user.company_id, id: params[:id]).first
    @note = @customer.task_note || @customer.build_task_note
    @note.body = params[:note][:body]

    if @note.save
      render json: @note
    else
      render json: {errors: @note.errors}, status: :unprocessable_entity
    end
  end

  def update_ready_task_note
    @customer = Customer.where(company_id: current_user.company_id, id: params[:id]).first
    @note = @customer.ready_task_note || @customer.build_ready_task_note
    @note.body = params[:note][:body]

    if @note.save
      render json: @note
    else
      render json: {errors: @note.errors}, status: :unprocessable_entity
    end
  end

  def search_by_phone
    if params[:phone].present?
    customers_results = ::Customer.ransack(
        contact_phone_eq: params[:phone],
      ).result.where(company_id: current_user.company_id)

      if customers_results.count > 0
        return render json: { present: true, customer: customers_results.first }, status: 200
      end
    end
    return render json: { present: false }, status: 404
  end

  private

  def customer_params
    params.require(:customer).permit(
      :first_name,
      :contact_phone,
      :contact_email,
      :contact_website,
      :name,
      :address,
      :city,
      :country,
      :vat,
      :postcode
    )
  end
end
