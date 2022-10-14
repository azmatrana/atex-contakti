class CompanyFilesController < ApplicationController
  before_action :set_company

  def index
    render json: @current_company.files.as_json(methods: [:humanize_file_size])
  end

  def create
    file = params[:file]
    company_file = @current_company.files.new(file: file)
    if company_file.save
      render json: {ok: true, success: t("company_files.file_create_success")}
    else
      render json: {errors: company_file.errors.full_messages.to_sentence}, status: 400
    end
  end

  def destroy
    @company_file = @current_company.files.find_by_id(params[:id])
    if @company_file && @company_file.destroy
      render json: {ok: true, success: t("company_files.file_delete_success")}
    else
      render json; {ok: false}
    end
  end

  private

  def set_company
    @current_company = current_user.company
  end
end
