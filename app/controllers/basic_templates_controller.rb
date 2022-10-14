class BasicTemplatesController < ApplicationController
  before_action :set_company
  def index
    @templates = @current_company.basic_templates.order('created_at DESC')
    respond_to do |format|
      format.html  # index.html.erb
      format.json {
        render json: @templates
      }
    end
  end

  def create
    @template = @current_company.basic_templates.new(title: params[:title], text: params[:text])
    if @template.save
      render :json => { data: @template, success: t('tags.templates_tab.template_save_success')}
    else
      render json: {errors: @template.errors.full_messages}
    end
  end

  def update
    @template = @current_company.basic_templates.find_by_id(params[:id])
    if @template.update(title: params[:title], text: params[:text] )
      render :json => { data: @template, success: t('tags.templates_tab.template_save_success')}
    else
      render :json => { :errors => @template.errors.full_messages }
    end
  end

  def destroy
    @template = @current_company.basic_templates.find_by_id(params[:id])
    if @template.destroy
      render json: { success: t('tags.templates_tab.template_delete_success')}
    else
      render json:{ :errors => @template.errors.full_messages}
    end
  end


  private

  def set_company
    @current_company = current_user.company
  end
end
