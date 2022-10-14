module ManagerSteps
  include Warden::Test::Helpers
  Warden.test_mode!

  step 'I should be on manager dashboard' do
    expect(current_path).to match /\A\/main_dashboard|\/en\/main_dashboard\z/
  end

  step 'manager exists' do
    @company ||= ::FactoryGirl.create :company
    @manager = ::FactoryGirl.create :manager, company: @company
  end

  step 'manager exists with email :email and password :password' do |email, password|
    @company ||= ::FactoryGirl.create :company
    @manager = ::FactoryGirl.create :manager, company: @company, email: email
    @manager.password = password
    @manager.save
  end

  step 'manager is logged in' do
    unless @manager
      send 'manager exists'
    end
    login_as(@manager, scope: :user)
  end

  step 'I am on service channels page' do
    visit service_channels_path
  end

  step 'I am on new service channel page' do
    visit new_service_channel_path
  end

  step 'there exists location with name :name' do |name|
    @company ||= ::FactoryGirl.create :company
    @location = ::FactoryGirl.create :location, company: @company, name: name
  end

  step 'I checked :name location' do |name|
    location = ::Location.where(name: name).first
    if location
      find("label[for='service_channel_location_ids_#{location.id}']").click
    end
  end

  step 'I (am) redirected to service channel :name' do |name|
    service_channel = ::ServiceChannel.where(name: name).first
    expect(current_path).to eq(service_channel_path(id: service_channel.id, locale: :en))
  end
end
