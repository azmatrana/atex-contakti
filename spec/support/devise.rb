module ControllerHelpers
  def sign_in(user = ::FactoryGirl.create(:user))
    if user.nil?
      allow(request.env['warden']).to receive(:authenticate!).and_throw(:warden, { :scope => :user })
      allow(controller).to receive(:current_user).and_return(nil)
    else
      warden.cookies.signed['session_id'] = {
        :value   => ::User::Session.activate(user).session_id,
        :expires => 1.year.from_now
      }
      allow(request.env['warden']).to receive(:authenticate!).and_return(user)
      allow(controller).to receive(:current_user).and_return(user)
    end
  end
end

RSpec.configure do |config|
  config.include Devise::TestHelpers, type: :controller
  config.include ControllerHelpers, type: :controller
end
