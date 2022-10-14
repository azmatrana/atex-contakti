require 'uri'
require 'tempfile'

module ContaktiCDR
  class Transcripts
    def initialize(message_id)
      @message = Message.find_by_id(message_id)
      return false if @message.blank?
      return false if !@message.task.company.allow_call_translation?

      @credentials = {email: ENV["CDR_EMAIL"], password: ENV["CDR_PASSWORD"]}
      @bearer_token = nil
      @audio_store_id = nil

      @call_recording_attachment = @message.call_recording_attachment

      @host = ENV['CDR_HOST']
      @use_ssl = ENV['CDR_SSL_PROTOCOL'].to_s.eql?("true")


      # @host = "https://cdr.contakti.com/callrecording"
      # @use_ssl = true
    end

    def make_login_request
      uri          = URI.parse("#{@host}/api/v1/login")
      http         = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = @use_ssl
      req          = Net::HTTP::Post.new(uri.request_uri)
      req['X-Requested-With'] = 'XMLHttpRequest'
      req['Content-Type'] = 'application/json'
      req.set_form_data(@credentials)

      _call = http.request(req)
      response_body = JSON.parse( _call.response.body)

      if (response_body["status"] == 200)
        @bearer_token = response_body["data"]["token"]
      end
    end

    def store_call_log
      if @bearer_token.present? && @call_recording_attachment.present?
        file_name = @call_recording_attachment.file_name
        @audio_file_contect = @call_recording_attachment.file.file.read

        file = Tempfile.new([file_name, File.extname(file_name)])
        IO.binwrite(file, @audio_file_contect)

        uri          = URI.parse("#{@host}/api/v1/store-call-log")
        http         = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = @use_ssl
        req          = Net::HTTP::Post.new(uri.request_uri)
        req['X-Requested-With'] = 'XMLHttpRequest'
        req['Content-Type'] = 'application/json'
        req['Authorization'] = "Bearer #{@bearer_token}"

        req.set_form([
          ['audio_file',   File.new(file, 'rb')],
          ['phone_number', "------------------"],
          ['is_google',    1],
          ['type',         "recording"],
          ['name',         "contakti-browser-recording"],
          ['unique_id',    "contakti-message-id: #{@message.id}"],
        ], 'multipart/form-data')

        _call = http.request(req)

        response_body = JSON.parse(_call.response.body)

        file.close
        file.unlink
        if (response_body["status"] == 200)
          @audio_store_id = response_body["data"]["id"]
          if @message.present?
            @message.update_attribute(:cdr_call_log_id, @audio_store_id)
          end
        end
      end
    end

    def get_transcript
      if @bearer_token.present? && @call_recording_attachment.present? && @audio_store_id.present?
        uri          = URI.parse("#{@host}/api/v1/get-transcript")
        http         = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = @use_ssl
        req          = Net::HTTP::Post.new(uri.request_uri)
        req['X-Requested-With'] = 'XMLHttpRequest'
        req['Content-Type'] = 'application/json'
        req['Authorization'] = "Bearer #{@bearer_token}"

        req.set_form_data({id: @audio_store_id})
        _call = http.request(req)

        response_body = JSON.parse( _call.response.body)

        if (response_body["status"] == 200)
          @message.update_attribute(:call_transcript, response_body["data"]["transcript"])
          @message.push_message_to_browser
          task = @message.task
          task.post_to_wit_api(task)
          task.save
        end

      end
    end

    def fetch_and_populate_tranlations
      self.make_login_request
      self.store_call_log
      self.get_transcript
    end

  end
end
