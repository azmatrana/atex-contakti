class Chatbot::ProductImagesController < ApplicationController

   def create
    file = params[:file]
    company_file = @current_company.files.new(file: file)
    if company_file.save
      render json: {ok: true, success: t("company_files.file_create_success")}
    else
      render json: {errors: company_file.errors.full_messages.to_sentence}, status: 400
    end
   end

end