require 'rails_helper'

describe LocationsController do

  let(:company) { ::FactoryGirl.create :company }
  let(:user) { ::FactoryGirl.create :manager, company: company }
  let(:service_channel1) { ::FactoryGirl.create :service_channel, company: company }
  let(:service_channel2) { ::FactoryGirl.create :service_channel, company: company }

  before(:each) do
    sign_in(user)
  end

  context 'permissions' do
    
    let(:another_company) { ::FactoryGirl.create :company }
    let(:location) { ::FactoryGirl.create :location, company: another_company }

    it 'should not let user see locations from another company' do
      get :index, id: location.id
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
    end

    it 'should not let user edit locations from another company' do
      put :update, id: location.id, 
        location: { 
          name: 'This location is under our control'
        }
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
      expect(location.name).not_to eq('This location is under our control')
    end

    it 'should not let user delete locations from another company' do
      delete :destroy, id: location.id
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
      expect(::Location.count).to eq(1)
    end

  end

end
