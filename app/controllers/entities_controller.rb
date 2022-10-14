class EntitiesController < ApplicationController
  before_action :set_company
  before_action :set_entity, only: [:update, :destroy]

  def index
    render json: @current_company.entities.order('id ASC').as_json(only: [:id, :name, :key_words])
  end

  def create
    @entity = @current_company.entities.new(name: params[:name])
    begin
      if @entity.save
        render :json => { data: @entity, success: t('user_dashboard.training.entity_create_success')}
      else
        render :json => { :errors => @entity.errors.full_messages }
      end
    rescue => e
      render :json => { :errors => e.message }
    end
  end

  def update
    begin
      if @entity.update(key_words: params[:key_words] ? params[:key_words].values : [])
        render :json => { data: @entity, success: t('user_dashboard.training.entity_save_success')}
      else
        render :json => { :errors => @entity.errors.full_messages }
      end
    rescue => e
      render :json => { :errors => e.message }
    end
  end

  def destroy
    begin
      if @entity.destroy
        render json: {success: t('user_dashboard.training.entity_delete_success')}
      else
        render json:{ :errors => @entity.errors.full_messages}
      end
    rescue => e
      render :json => { :errors => e.message }
    end
  end

  private

  def set_company
    @current_company = current_user.company
  end

  def set_entity
    @entity = @current_company.entities.find_by_id(params[:id])
  end

end
