class TemplateRepliesController < ApplicationController
  before_action :set_company

  def index
    @templates = @current_company.template_replies.order('created_at DESC')
    respond_to do |format|
      format.html  # index.html.erb
      format.json {
        render json: @templates
      }
      end
  end

  def create
    @template = @current_company.template_replies.new(:text => params[:template_text])
    if @template.save
      render json:{ data: @template , success: 'Reply Template Saves Successfully'}
    else
      render json: {errors: @template.errors.full_messages}
    end
  end

  def update
    @template = @current_company.template_replies.find_by_id(params[:id])
    if @template.update(text: params[:text] ? params[:text]: "")
      render :json => { data: @template, success: t('tags.templates_tab.template_save_success')}
    else
      render :json => { :errors => @template.errors.full_messages }
    end
  end

  def show
    @template = @current_company.template_replies.find_by_id(params[:id])
    respond_to do |format|
      format.html  # index.html.erb
      format.json {
        render json: @template
      }
    end

  end

  def destroy
    @template = @current_company.template_replies.find_by_id(params[:id])
    if @template.destroy
      render json: { success: t('user_dashboard.template_delete_message')}
    else
      render json:{ :errors => @template.errors.full_messages}
    end
  end

  private

  def set_company
    @current_company = current_user.company
  end
end
