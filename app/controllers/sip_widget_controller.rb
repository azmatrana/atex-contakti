require 'uglifier'

class SipWidgetController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:show]
  skip_before_filter :verify_authenticity_token, :authenticate_user!, :update_current_session

  layout false

  def show
    media_channel = MediaChannel::Sip.find_by_id(params[:id])
    if (media_channel.present? && media_channel.sip_settings.present? && media_channel.sip_settings.sip_widget.present?)
      @sip_settings = media_channel.sip_settings
    else
      render json: "404"
    end

    respond_to do |format|
      format.js { self.response_body = minify(render_to_string) }
    end
  end

  def minify(content)
    return Uglifier.compile(content, {:mangle => {
        :toplevel => true,         # Mangle names declared in the toplevel scope
        :properties => true,       # Mangle property names
        :sort => true,              # Mangle property names
        :keep_fnames => false       # Do not modify function names
      }, :output => { :comments => :copyright },
    })

end

  def test
    media_channel = MediaChannel::Sip.find_by_id(params[:id])
    if (media_channel.present? && media_channel.sip_settings.present? && media_channel.sip_settings.sip_widget.present?)
      @sip_settings = media_channel.sip_settings
    else
      render json: "404"
    end
  end
end
