class TagsController < ApplicationController
  before_action :check_admin_access, except: [:download_phonebook_template_file]
  before_action :set_company, only: :save_kimai_url

  def index
    @skills = current_user.company.skills
    @skill_counts = current_user.company.tag_usage_count
  end

  def save_kimai_url
    @current_company.kimai_tracker_api_url = params[:kimai_tracker_api_url]
  end

  def cleanup
    if params[:tag].present?
      current_user.company.tasks.tagged_with(params[:tag], on: :generic_tags).each do |task|
        task.generic_tag_list.remove(params[:tag])
        task.save
      end
    end
    redirect_to tags_path
  end

  def destroy_skills
    if params[:tag].present?
      tag = current_user.company.skills.find_by_name(params[:tag])
      current_user.company.skill_list.remove(params[:tag])
      if tag.present?
        priority = Priority.find_by_tag_id(tag.id)
        priority.try(:destroy)
      end
      # Convert task skill tags to generic tags because the company skill has been removed
      current_user.company.tasks.tagged_with(params[:tag], on: :skills).each do |task|
        task.skill_list.remove(params[:tag])
        task.generic_tag_list.add(params[:tag])
        task.save
      end

      current_user.company.agents.tagged_with(params[:tag], on: :skills).each do |agent|
        agent.skill_list.remove(params[:tag])
        agent.save
      end

      current_user.company.save
      current_user.company.touch # invalidate tag cache
    end


    redirect_to tags_path
  end

  def create_skills
    if params[:tags].present?
      params[:tags].split(',').each do |tag|
        sanitized = tag.downcase.gsub(/[^a-zåäö0-9@\.\-\_\+\?\/\:]/, "").gsub(/\&.+?;/, "").gsub(/%\d+/, "")
        current_user.company.skill_list.add(sanitized) unless sanitized.blank?
        # Convert task generic tags to skill tags when a matching skill has been added to company
        current_user.company.tasks.tagged_with(sanitized, on: :generic_tags).each do |task|
          task.generic_tag_list.remove(sanitized)
          task.skill_list.add(sanitized)
          task.save
        end
      end
      current_user.company.save
      current_user.company.touch # invalidate tag cache
    end
    redirect_to tags_path
  end

  def upload_contacts
    if params[:csv].blank?
      return render json: { errors:  I18n.t('errors.messages.csv_not_present') }, status: 400
    else
      errors = []
      begin
        CSV.read(params[:csv].path, col_sep: ";", encoding: 'ISO8859-1' ).each_with_index do |row, index|
          next if index == 0
          attributes = {
            name: row[0],
            address: row[1],
            postcode: row[2],
            city: row[3],
            country: row[4],
            contact_phone: row[5],
            contact_email: row[6],
            vat: row[7],
            first_name: row[8],
            contact_website: row[9],
            company_id: current_user.company_id
          }
          customer = Customer.new(attributes)
          unless customer.save
            errors += customer.errors.full_messages
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

  def download_phonebook_template_file
    header  = 'FIRST-NAME;'
    header << 'LAST-NAME;'
    header << 'PHONENUMBER;'
    header << 'EMAIL;'
    header << 'ADDRESS;'
    header << 'POSTNUMBER;'
    header << 'CITY;'
    header << 'COUNTRY;'
    header << 'WEBPAGE;'
    header << 'Y-TUNNUS;'
    out_file = File.new("tmp/phonebook_template_file.csv", "w")
    out_file.puts(header)
    out_file.close
    out_file = File.new("tmp/phonebook_template_file.csv", "r")
    send_data out_file.read, filename: 'phonebook_template_file.csv'
  end

  def download_template_file
    header = 'NAME;'
    header << 'ADDRESS;'
    header << 'POSTNUMBER;'
    header << 'CITY;'
    header << 'COUNTRY;'
    header << 'PHONENUMBER;'
    header << 'EMAIL;'
    header << 'Y-TUNNUS;'
    header << 'CONTACTPERSON;'
    header << 'WEBPAGE'
    out_file = File.new("tmp/template_file.csv", "w")
    out_file.puts(header)
    out_file.close
    out_file = File.new("tmp/template_file.csv", "r")
    send_data out_file.read, filename: 'template_contacts.csv'
  end

  def select_time
    @time = params[:expire_time].to_i
    @skill = ActsAsTaggableOn::Tag.find(params["id"])
    @skill_counts = current_user.company.tag_usage_count
    @success = true
    @message = ""

    if @time.present?
      priority = Priority.find_by(company_id: current_user.company, tag_id: params['id'] )
      if priority and priority.update(expire_time: @time)
        @message = "#{I18n.t('tag_notifications.time_success')} #{@skill.name}"
      else
        @success = false
        @message = "#{I18n.t('tag_notifications.time_failure')} #{@skill.name}"
      end
    end

    unless request.xhr?
      redirect_to tags_path
    else
      render "tags/tag"
    end
  end

  def set_priority
    @priority = params[:priority]["priority_set"].to_i
    @skill = ActsAsTaggableOn::Tag.find(params["id"])
    @skill_counts = current_user.company.tag_usage_count
    @success = true
    @message = ""

    if entry = Priority.find_by(company_id: params[:company],tag_id: params[:id])
      if entry.update(priority_value: @priority)
        @message = "#{I18n.t('tag_notifications.priority_success')} #{@skill.name}"
      else
        @success = false
        @message = "#{I18n.t('tag_notifications.priority_failure')} #{@skill.name}"
      end
    else
      if Priority.create(company_id: params[:company],tag_id: params[:id], priority_value: @priority)
        @message = "#{I18n.t('tag_notifications.priority_add')} #{@skill.name}"
      else
        @success = false
        @message = "#{I18n.t('tag_notifications.priority_add_failure')} #{@skill.name}"
      end
    end

    Rails.cache.delete("priority_#{current_user.company_id}_cache_key")

    Rails.cache.fetch("priority_#{current_user.company_id}_cache_key") do
      Priority.where(company_id: current_user.company_id).pluck(:tag_id, :priority_value).to_h
    end

    unless request.xhr?
      redirect_to tags_path
    else
      render "tags/tag"
    end
  end

  def update_alarm_receivers
    @skill = ActsAsTaggableOn::Tag.find(params["id"])
    entry = Priority.find_by(company_id: params[:company], tag_id: params[:id])

    @success = true
    @message = ""

    if entry.present? && entry.update(alarm_receiver_params)
      @message = "#{I18n.t('tag_notifications.alarm_receivers_success')} #{@skill.name}"
    else
      @success = false
      @message = "#{I18n.t('tag_notifications.alarm_receivers_failure')} #{@skill.name}"
    end

    unless request.xhr?
      redirect_to tags_path
    else
      render "tags/tag"
    end
  end

  def update_email_template
    @skill = ActsAsTaggableOn::Tag.find(params["id"])
    entry = Priority.find_by(company_id: params[:company], tag_id: params[:id])

    @success = true
    @message = ""

    if entry.present? && entry.update(email_template_params)
      @message = "#{I18n.t('tag_notifications.email_template_success')} #{@skill.name}"
    else
      @success = false
      @message = "#{I18n.t('tag_notifications.email_template_failure')} #{@skill.name}"
    end
  end

  def update_sms_template
    @skill = ActsAsTaggableOn::Tag.find(params["id"])
    entry = Priority.find_by(company_id: params[:company], tag_id: params[:id])

    @success = true
    @message = ""

    if entry.present? && entry.update(sms_template_params)
      @message = "#{I18n.t('tag_notifications.sms_template_success')} #{@skill.name}"
    else
      @success = false
      @message = "#{I18n.t('tag_notifications.sms_template_failure')} #{@skill.name}"
    end
  end

  private

    def alarm_receiver_params
      params.require(:priority).permit(:alarm_receivers)
    end

    def email_template_params
      params.require(:priority).permit(:email_template)
    end

    def sms_template_params
      params.require(:priority).permit(:sms_template)
    end

    def set_company
      @current_company = current_user.company
    end
end

