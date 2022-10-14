class Chatbot::ProductsController < ApplicationController
  before_action :set_company

  def index
    render json: @current_company.products.as_json(methods: [:answers_count], include: [:images, :attachments, :vat])
  end

  def show
    @product = @current_company.products.find_by_id(params[:id]) rescue nil
    if @product.present?
      render json: {data: @product.as_json( include: [:images, :attachments, :vat])}
    end
  end

  def create
    @product = @current_company.products.new(product_params)
    if @product.save
      render json: { data: @product.as_json( include: [:images, :attachments, :vat]), success: t('products.create_success')}
    else
      render :json => { :errors => @product.errors.full_messages }
    end
  end

  def update
    @product = @current_company.products.find(params[:id])
    if @product.update(product_params)
      render json: { data: @product.as_json( include: [:images, :attachments, :vat]), success: t('products.update_success')}
    else
      render :json => { :errors => @product.errors.full_messages }
    end
  end

  def upload_attachments
     @product = @current_company.products.find(params[:id])
     if @product.update(product_params)
      render json: { data: @product.as_json( include: [:images, :attachments]), success: t('products.update_success')}
    else
      render :json => { :errors => @product.errors.full_messages }
    end
  end

  def destroy
    # TODO : Destroy associated answers.
    @product = @current_company.products.find(params[:id])
    if @product.destroy
      render json: { success: t('products.delete_success')}
    else
      render json:{ :errors => @product.errors.full_messages}
    end
  end

  def get_company_vats_and_currency
    render json: {vats: @current_company.vats.order(vat_percentage: :asc), currency: @current_company.currency}
  end


  private
  def product_params
    params.require(:product).permit(
      :title,
      :currency,
      :price,
      :with_vat,
      :vat_id,
      :description,
      images_attributes: [:file, :id, :_destroy],
      attachments_attributes: [:file, :id, :_destroy]
      )
  end
  def set_company
    @current_company = current_user.company
  end
end
