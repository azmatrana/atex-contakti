require 'rails_helper'

describe AgentsController do

  let(:company) { ::FactoryGirl.create :company }
  let(:manager) { ::FactoryGirl.create :manager, company: company }
  let(:service_channel1) { ::FactoryGirl.create :service_channel, company: company }
  let(:service_channel2) { ::FactoryGirl.create :service_channel, company: company }
  let(:location1) { ::FactoryGirl.create :location, company: company }
  let(:location2) { ::FactoryGirl.create :location, company: company }

  before(:each) do
    sign_in(manager)
  end

  context 'permissions' do
    
    let(:another_company) { ::FactoryGirl.create :company }
    let(:agent) { ::FactoryGirl.create :agent, company: another_company }

    it 'should not let manager see agent from another company' do
      get :index, id: agent.id
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
    end

    it 'should not let manager edit agents from another company' do
      put :update, id: agent.id, 
        user: { 
          first_name: 'Hacked'
        }
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
      expect(agent.first_name).not_to eq('Hacked')
    end

    it 'should not let manager delete agents from another company' do
      delete :destroy, id: agent.id
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
      expect(::User.with_role(:agent).count).to eq(1)
    end

  end

end
