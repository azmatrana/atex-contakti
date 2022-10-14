class SynonymsController < ApplicationController
  before_action :set_company

  def create
    @key_word = KeyWord.find_by_id(params[:key_word_id])
    @synonym = @key_word.synonyms.new(text: params[:text])if @key_word.present?
    if @synonym.save
      render :json => { data: @synonym, success: "Synonym Created Successfully" }
    else
      render :json => { :errors => @synonym.errors.full_messages }
    end
  end

end