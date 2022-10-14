class IntentsController < ApplicationController
  before_action :set_company

  def index
    @intents = @current_company.intents.all
    render json: @intents
  end

  def create
    @intent = @current_company.intents.find_by(text: intent_params)
    unless @intent
      company = current_user.company
      @intent = company.intents.new(text: intent_params)
      if @intent.save
        return render json:{data: @intent, success: t('user_dashboard.training.intent_create_success')}
      else
        return render :json => { :errors => @intent.errors.full_messages }
      end
    end
    render json:{data: @intent, success: t('user_dashboard.training.intent_already_present'), present_already: true}
  end
  def destroy
    @intent = @current_company.intents.find(params[:id])
    if @intent.destroy
      render json: { success: t('user_dashboard.training.intent_delete_message')}
    else
      render json:{ :errors => @intent.errors.full_messages}
    end
  end

  private

  def set_company
    @current_company = current_user.company
  end

  def intent_params
    params[:text]
  end

end
