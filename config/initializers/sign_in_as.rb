require 'devise/strategies/base'

module SignInAs
  module Devise
    module Strategies
      class FromAdmin < ::Devise::Strategies::Base
        include SignInAs::Concerns::RememberAdmin

        def valid?
          logger.debug 'In FromAdmin valid?'
          remember_admin_id?
        end

        def authenticate!
          resource = User.find(remember_admin_id)
          if resource
            logger.debug 'In FromAdmin authenticate!'
            clear_remembered_admin_id
            success!(resource)
          else
            pass
          end
        end
      end
    end
  end
end

Warden::Strategies.add(:sign_in_as, SignInAs::Devise::Strategies::FromAdmin)