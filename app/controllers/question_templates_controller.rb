class QuestionTemplatesController < ApplicationController
  before_action :set_company

  def index
    render json: @current_company.question_templates
  end

  def subscribe_to_danthes
    channel = "/understandings/#{@current_company.id}"
    render json: ::Danthes.subscription(channel: channel)
  end

  def create_question_from_template
    @template = @current_company.question_templates.find_by_id(params[:id])
    text = @template.text
    if text.present? && text.class == String
      text = text.squish
    end
    @question = @current_company.questions.where('lower(text) = ?', text.downcase).first_or_initialize(text: text)
    @question.intent_id = params[:intent_id]

    if @question.save
      if @template.destroy
        render json: { success: t('user_dashboard.training.understanding_to_question')}
      else
        render :json => { :errors => @template.errors.full_messages }
      end
    else
      render :json => { :errors => @question.errors.full_messages }
    end
  end

  def destroy
    @template = @current_company.question_templates.find_by_id(params[:id])
    if @template.destroy
      render json: { success: t('user_dashboard.training.question_template_delete_success')}
    else
      render json:{ :errors => @template.errors.full_messages}
    end

  end

  def destroy_all
    @templates = @current_company.question_templates
    if @templates.destroy_all
      render json: { success: t('user_dashboard.training.question_template_delete_success')}
    else
      render json:{ :errors => @templates.errors.full_messages}
    end
  end

  private

  def set_company
    @current_company = current_user.company
  end

end
