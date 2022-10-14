require 'rails_helper'

describe ServiceChannelsController do

  let(:company) { ::FactoryGirl.create :company }
  let(:user) { ::FactoryGirl.create :manager, company: company }
  let(:location1) { ::FactoryGirl.create :location, company: company }
  let(:location2) { ::FactoryGirl.create :location, company: company }

  before(:each) do
    sign_in(user)
  end

  context 'create' do

    it 'should create new service channel' do
      post :update, service_channel: { 
        name: 'Test service channel',
        yellow_alert_hours: 3, 
        yellow_alert_days: 0, 
        red_alert_hours: 5,
        red_alert_days: 0,
        location_ids: [ location1.id ]
      }
      expect(response).to have_http_status(302)
      expect(::ServiceChannel.count).to equal(1)
      expect(::MediaChannel.count).to equal(0)
      expect(::ImapSettings.count).to equal(0)
      expect(::SmtpSettings.count).to equal(0)
    end

    it 'should not create empty media channels & settings if login/password is autofilled by browser' do
      post :update, service_channel: { 
        name: 'Test service channel',
        yellow_alert_hours: 3, 
        yellow_alert_days: 0, 
        red_alert_hours: 5,
        red_alert_days: 0,
        location_ids: [ location1.id ],
        email_media_channel_attributes: {
          active: '1',
          imap_settings_attributes: {
            description: '',
            port: '143',
            user_name: 'manager@dotpromo.me',
            password: 'password'
          }
        }
      }
      expect(response).to have_http_status(302)
      expect(::ServiceChannel.count).to equal(1)
      expect(::MediaChannel.count).to equal(0)
      expect(::ImapSettings.count).to equal(0)
      expect(::SmtpSettings.count).to equal(0)
    end

    it 'should save email media channel on save if all required fields are filled' do
      post :update, service_channel: { 
        name: 'Test service channel',
        yellow_alert_hours: 3, 
        yellow_alert_days: 0, 
        red_alert_hours: 5,
        red_alert_days: 0,
        location_ids: [ location1.id ],
        email_media_channel_attributes: {
          active: '1',
          imap_settings_attributes: {
            description: '',
            port: '143',
            user_name: 'manager@dotpromo.me',
            password: 'password',
            server_name: 'imap.blacorp.com'
          }
        }
      }
      expect(response).to have_http_status(302)
      expect(::ServiceChannel.count).to equal(1)
      expect(::MediaChannel::Email.count).to equal(1)
      expect(::ImapSettings.count).to equal(1)
    end

    it 'should save SMTP settings for web form media channel if all required fields are filled' do
      post :update, service_channel: { 
        name: 'Test service channel',
        yellow_alert_hours: 3, 
        yellow_alert_days: 0, 
        red_alert_hours: 5,
        red_alert_days: 0,
        location_ids: [ location1.id ],
        web_form_media_channel_attributes: {
          active: '1',
          smtp_settings_attributes: {
            description: '',
            port: '465',
            user_name: 'manager@dotpromo.me',
            password: 'password',
            server_name: 'smtp.blacorp.com',
            auth_method: 'login'
          }
        }
      }
      expect(::ServiceChannel.count).to equal(1)
      expect(::MediaChannel::WebForm.count).to equal(1)
      expect(::ImapSettings.count).to equal(0)
      expect(::SmtpSettings.count).to equal(1)
    end

    it 'should not create Call media channel if params are empty' do
      post :update, service_channel: { 
        name: 'Test service channel',
        yellow_alert_hours: 3, 
        yellow_alert_days: 0, 
        red_alert_hours: 5,
        red_alert_days: 0,
        location_ids: [ location1.id ],
        call_media_channel_attributes: {
          active: '1',
          group_id: '',
          send_autoreply: '1',
          autoreply_text: ''
        }
      }
      expect(::ServiceChannel.count).to equal(1)
      expect(::MediaChannel::Call.count).to equal(0)
    end

    it 'should save Call media channel if group id is set' do
      post :update, service_channel: { 
        name: 'Test service channel',
        yellow_alert_hours: 3, 
        yellow_alert_days: 0, 
        red_alert_hours: 5,
        red_alert_days: 0,
        location_ids: [ location1.id ],
        call_media_channel_attributes: {
          active: '1',
          group_id: 'blaaa',
          send_autoreply: '1',
          autoreply_text: ''
        }
      }
      expect(::ServiceChannel.count).to equal(1)
      expect(::MediaChannel::Call.count).to equal(1)
      expect(::MediaChannel::Call.first.group_id).to eq('blaaa')
    end

  end

  context 'update' do

    let(:service_channel) { ::FactoryGirl.create :service_channel, company: company }

    it 'should update existing service channel' do
      put :update, id: service_channel.id, 
        service_channel: { 
          name: 'Bla service channel',
          yellow_alert_hours: 2.5
        }
      expect(response).to have_http_status(200)
      expect(::ServiceChannel.count).to equal(1)
      service_channel.reload
      expect(service_channel.name).to eq('Bla service channel')
      expect(service_channel.yellow_alert_hours).to eq(2.5)
    end


    it 'should update email channel IMAP settings' do
      put :update, id: service_channel.id, 
        service_channel: { 
          email_media_channel_attributes: {
            active: '1',
            imap_settings_attributes: {
              description: 'olololo description',
              server_name: 'imap.opana.com',
              port: '143',
              user_name: 'manager@dotpromo.me',
              password: 'password'
            }
          }
        }
      expect(response).to have_http_status(200)
      service_channel.reload
      expect(service_channel.email_media_channel.imap_settings.description).to eq('olololo description')
    end

    it 'should be able to add users to existing service channel' do
      agent = ::FactoryGirl.create :agent, company: company
      another_agent = ::FactoryGirl.create :agent, company: company
      put :update, id: service_channel.id, 
        service_channel: { 
          user_ids: [agent.id, another_agent.id]
        }
      expect(response).to have_http_status(200)
      expect(service_channel.reload.user_ids).to eq([agent.id, another_agent.id])
    end

  end

  context 'delete' do
    
    let(:service_channel) { ::FactoryGirl.create :service_channel, company: company }

    it 'should delete service channel record in background' do
      delete :destroy, id: service_channel.id
      expect(response).to have_http_status(302)
      expect(::ServiceChannelDestroyWorker.jobs.size).to eq(1)
      ::ServiceChannelDestroyWorker.drain
      expect(::ServiceChannel.count).to eq(0)
    end

  end

  context 'permissions' do
    
    let(:another_company) { ::FactoryGirl.create :company }
    let(:service_channel) { ::FactoryGirl.create :service_channel, company: another_company }

    it 'should not let user see service channels from another company' do
      get :index, id: service_channel.id
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
    end

    it 'should not let user edit service channels from another company' do
      put :update, id: service_channel.id, 
        service_channel: { 
          name: 'All you base are belong to us',
        }
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
      expect(service_channel.name).not_to eq('All you base are belong to us')
    end

    it 'should not let user delete service channels from another company' do
      delete :destroy, id: service_channel.id
      expect(response).to have_http_status(302)
      expect(flash[:alert]).not_to be_empty
      expect(::ServiceChannelDestroyWorker.jobs.size).to eq(0)
      ::ServiceChannelDestroyWorker.drain
      expect(::ServiceChannel.count).to eq(1)
    end

  end

end
