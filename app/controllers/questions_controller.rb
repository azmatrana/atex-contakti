class QuestionsController < ApplicationController
  before_action :set_company
  def index
    render json: @current_company.questions.as_json(include: [:intent])
  end

  def create
    @intent = @current_company.intents.find_by_id(params[:intent_attributes][:intent_id])
    text = params[:text]
    if params[:text].present? && params[:text].class == String
      text = text.squish
    end
    @question = @current_company.questions.where('lower(text) = ?', text.downcase).first_or_initialize(text: text)
    @question.intent = @intent if @intent.present?
    if @question.save
      render :json => { data: @question, success: t('user_dashboard.training.question_create_success') }
    else
      render :json => { :errors => @question.errors.full_messages }
    end
  end

  def destroy
    @question = @current_company.questions.find(params[:id])
    if @question.destroy
      render json: { success: t('user_dashboard.training.question_delete_message')}
    else
      render json:{ :errors => @question.errors.full_messages}
    end
  end

  private

  def question_params
    params[:text]
  end
  def set_company
    @current_company = current_user.company
  end

end
