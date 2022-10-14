require 'uri'

module Fonnecta
  class Contacts
    def initialize(company, phone_number)
      @credential = ::Fonnecta::Credential.first
      @company = company
      @phone_number = phone_number
    end

    def contact_cache
      @contact_cache ||= ::Fonnecta::ContactCache.where(phone_number: @phone_number, company: @company).first_or_initialize
    end

    def search
      return '' unless @credential
      return '' if @phone_number == '+Unavailable'
      return '' if @phone_number.length < 5
      # return contact_cache.full_name if contact_cache.persisted? && contact_cache.updated_at >= ::Time.current - 30.days
      authorize unless @credential.token_usable?
      if contact = fetch
        contact_cache.full_name = contact['name']
        contact_cache.city_name = contact['cityName'] rescue ''
        contact_cache.street_address = contact['address']['streetAddress'] rescue ''
        contact_cache.postal_code = contact['address']['postalCode'] rescue ''
        contact_cache.post_office = contact['address']['postOffice'] rescue ''
        contact_cache.save!
        contact['name']
      else
        contact_cache.full_name == nil ? '' : contact_cache.full_name
      end
    end


    def search_full_data
      search
      return contact_cache
    end

    def fetch
      uri = URI.parse('https://search.fonapi.fi/v2/contacts/search')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      params_part = {
        what: @phone_number,
        language: 'fi',
        results_per_page: 250,
        contact_type: 'ALL'
      }
      uri.query = URI.encode_www_form(params_part)
      req = Net::HTTP::Get.new(uri.request_uri)
      req['Authorization'] = "Bearer #{@credential.token}"
      result = http.request(req)
      ::Company::Stat.increment_counter(:name_checks, @company.current_stat.id)
      res = ::JSON.parse(result.body)
      return unless res['contacts']
      res['contacts'].find {|x| x['contactType'] =~ /person/i }
    end

    def authorize
      @credential.get_new_token!
    end

    def self.conver_text_to_phone(phone)
      phone = phone.tr('a-z|A-Z|:', '')
      return phone
    end

  end
end
