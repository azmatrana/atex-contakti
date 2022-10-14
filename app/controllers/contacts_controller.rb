class ContactsController < ApplicationController
  before_action :set_owner_objects
  before_action :set_contacts, only: [:index, :update, :search, :delete_all, :destroy, :upload_csv, :show]

  def index
  end

  def show
    @contact = @contacts.find_by_id(params[:id])
  end

  def search
    params[:public_phonebook] = params[:public_phonebook].present? && params[:public_phonebook] == "true"
    load_company_phonebook if params[:public_phonebook].present?
    @contacts = @contacts.ransack(
      m: 'or',
      first_name_cont: params[:search],
      last_name_cont: params[:search],
      phone_cont: params[:search],
      email_cont: params[:search],
      website_cont: params[:search],
      address_cont: params[:search],
      city_cont: params[:search],
      country_cont: params[:search],
      vat_cont: params[:search],
      postcode_cont: params[:search],
    ).result
  end

  def upload_csv
    if params[:csv].blank?
      return render json: { errors:  I18n.t('errors.messages.csv_not_present') }, status: 400
    else
      errors = []
      begin
        CSV.read(params[:csv].path, col_sep: ";", encoding: 'ISO8859-1' ).each_with_index do |row, index|
          next if index == 0

          attributes = {
            first_name: row[0],
            last_name: row[1],
            phone: row[2],
            email: row[3],
            address: row[4],
            postcode: row[5],
            city: row[6],
            country: row[7],
            website: row[8],
            vat: row[9]
          }

          contact = @contacts.new(attributes)
          unless contact.save
            errors += contact.errors.full_messages
          end
        end
      rescue Exception => ex
        errors << ex.message
      end
    end

    unless errors.blank?
      render json: { errors:  errors }, status: 400
    else
      render nothing: true
    end
  end

  def public_phonebook
    load_company_phonebook
  end

  def update
    @contact = @contacts.where(id: params[:id]).first
    @contact.assign_attributes(contact_params)
  end

  def destroy
    @contact = @contacts.find(params[:id])
  end

  def delete_all
    @contacts.destroy_all
    render :search
  end

  private

  def set_owner_objects
    if current_user.has_role? :agent
      @contacts_owner = current_user
    else
      @contacts_owner = current_user.company
    end
  end

  def load_company_phonebook
    @contacts = current_user.company.contacts.sort_by('last_name', :asc)
  end

  def set_contacts
    @contacts = @contacts_owner.contacts.sort_by('last_name', :asc)
  end

  def contact_params
    params.require(:contact).permit(
      :first_name,
      :last_name,
      :phone,
      :email,
      :website,
      :address,
      :city,
      :country,
      :vat,
      :postcode
    )
  end

end
