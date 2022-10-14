module Helpers
  module CommonUtils
    extend self

    def string_to_url(url='')
      unless url[/\Ahttp:\/\//] || url[/\Ahttps:\/\//]
        url = "http://#{url}"
      end
      return url
    end
  end
end
