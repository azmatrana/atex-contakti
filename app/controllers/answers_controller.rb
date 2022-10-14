class AnswersController < ApplicationController
  before_action :set_company

  def index
    render json: @current_company.answers.as_json(include: [:intent, :company_files, :answer_buttons, :products, :images])
  end

  def create
    @answer = @current_company.answers.new(answer_params)
    if params[:file_id].present?
      @file = @current_company.files.find_by_id(params[:file_id])
    end
    if @answer.save
      if @file.present?
        @answer.company_files << @file
      end
      render json: { data: @answer, success: t('user_dashboard.training.answer_create_success')}
    else
      render :json => { :errors => @answer.errors.full_messages }
    end
  end

  def create_or_update
    @answer = @current_company.answers.find_or_initialize_by(id: (params[:answer][:id] rescue nil) )
    if !@answer.new_record?
      # remove all associations and after that create new associations base on params.
      @answer.company_files = []
      @answer.products = []
    end
    @answer.assign_attributes(answer_params)
    if @answer.save
      render json: { data: @answer, success: t('user_dashboard.training.answer_create_success')}
    else
      render :json => { :errors => @answer.errors.full_messages }
    end
  end

  def destroy
    @answer = @current_company.answers.find_by_id(params[:id])
    if @answer.destroy
      render json: { success: t('user_dashboard.training.answer_delete_message')}

    else
      render json:{ :errors => @answer.errors.full_messages}
    end

  end


  private

  def set_company
    @current_company = current_user.company
  end
  def answer_params
    unless params[:answer_buttons_attributes].blank?
      params[:answer_buttons_attributes] =  params[:answer_buttons_attributes].values
    end
    params.require(:answer).permit(
      :text,
      :intent_id,
      :has_custom_action,
      :custom_action_text,
      :answer_buttons_attributes => [:id, :text, :hyper_link, :_destroy],
      :product_ids => [],
      :company_file_ids => [],
      :images_attributes => [:id, :file, :_destroy])
  end


end
