require 'rails_helper'

describe SmsTemplatesController do

  let(:company)         { ::FactoryGirl.create :company }
  let(:manager)         { ::FactoryGirl.create :manager, company: company }
  let(:service_channel) { ::FactoryGirl.create :service_channel, company: company }
  let(:location)        { ::FactoryGirl.create :location, company: company }

  before(:each) do
    sign_in manager
  end

  context 'agent templates' do

    context '#create' do
      
      it 'should create new template' do
        post :create, sms_template: {
          kind: 'agent',
          title: 'first template',
          text: 'Bla bla bla SMS',
          visibility: 'service_channel',
          service_channel_id: service_channel.id
        }, format: :js
        expect(response).to have_http_status(200)
        expect(assigns[:status_message]).to be
        expect(assigns[:status_message][:ok]).to eq(true)
        expect(::SmsTemplate.count).to eq(1)
      end

      it 'should create new template with visibility limited to location' do
        post :create, sms_template: {
          kind: 'agent',
          title: 'first template',
          text: 'Bla bla bla SMS',
          service_channel_id: service_channel.id,
          visibility: 'location',
          location_id: location.id
        }, format: :js
        expect(response).to have_http_status(200)
        expect(::SmsTemplate.count).to eq(1)
        expect(assigns[:sms_template].location_id).to eq(location.id)
      end

      it 'should create new template with visibility limited to company' do
        post :create, sms_template: {
          kind: 'agent',
          title: 'first template',
          text: 'Bla bla bla SMS',
          service_channel_id: service_channel.id,
          visibility: 'company'
        }, format: :js
        expect(response).to have_http_status(200)
        expect(::SmsTemplate.count).to eq(1)
        expect(assigns[:sms_template]).to eq(::SmsTemplate.first)
        expect(assigns[:sms_template].visibility).to eq('company')
        expect(assigns[:sms_template].company_id).to eq(company.id)
      end

      it 'should update existing template if template with such name already exists and save_as_new is false' do
        existing_template = ::FactoryGirl.create :agent_sms_template, title: 'existing template', service_channel: service_channel
        post :create, sms_template: {
          kind: 'agent',
          title: 'existing template',
          text: 'Bla bla bla SMS',
          visibility: 'service_channel',
          service_channel_id: service_channel.id,
          save_as_new: 'false'
        }, format: :js
        expect(response).to have_http_status(200)
        expect(::SmsTemplate.count).to eq(1)
        expect(assigns[:sms_template].errors).to be_empty
        sms_template = ::SmsTemplate.first
        expect(sms_template.text).to eq('Bla bla bla SMS')
      end

    end

    context '#delete' do

      let(:sms_template) { ::FactoryGirl.create :agent_sms_template, service_channel: service_channel }
      
      it 'should delete sms template' do
        delete :destroy, id: sms_template.id, format: :js
        expect(response).to have_http_status(200)
        expect(::SmsTemplate.count).to eq(0)
      end

    end

  end

  context 'manager templates' do

    context '#create' do

      it 'should create new template' do
        post :create, sms_template: {
          kind: 'manager',
          title: 'first manager template',
          text: 'Bla bla bla SMS template',
          service_channel_id: service_channel.id
        }, format: :js
        expect(response).to have_http_status(200)
        expect(assigns[:status_message]).to be
        expect(assigns[:status_message][:ok]).to eq(true)
        expect(::SmsTemplate.count).to eq(1)
      end

      it 'should update existing template if template with such name already exists and save_as_new is false' do
        existing_template = ::FactoryGirl.create :manager_sms_template, title: 'existing manager template', company: company
        post :create, sms_template: {
          kind: 'manager',
          title: 'existing manager template',
          text: 'template text goes here',
          service_channel_id: service_channel.id,
          save_as_new: 'false'
        }, format: :js
        expect(response).to have_http_status(200)
        expect(::SmsTemplate.count).to eq(1)
        expect(assigns[:sms_template].errors).to be_empty
        sms_template = ::SmsTemplate.where(kind: 'manager').first
        expect(sms_template.text).to eq('template text goes here')
      end

    end

    context '#delete' do

      let(:sms_template) { ::FactoryGirl.create :manager_sms_template, service_channel: service_channel, company: company }
      
      it 'should delete sms template' do
        delete :destroy, id: sms_template.id, format: :js
        expect(response).to have_http_status(200)
        expect(::SmsTemplate.count).to eq(0)
      end

    end

  end

end
