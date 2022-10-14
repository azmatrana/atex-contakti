class KeyWordsController < ApplicationController
  before_action :set_company

  def create
    @entity = Entity.find_by_id(params[:entity_id])
    @key_word = @entity.key_words.new(text: params[:text])
    if @key_word.save
      render :json => { data: @key_word, success: "Synonym Created Successfully" }
    else
      render :json => { :errors => @key_word.errors.full_messages }
    end

  end


end