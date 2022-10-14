require 'rails_helper'

describe CallDetailRecordsController, type: :controller do
  let(:company) { ::FactoryGirl.create(:company) }
  let(:service_channel) { ::FactoryGirl.create(:service_channel, company: company) }
  let(:credential) { ::FactoryGirl.create(:fonnecta_credential, client_id: 'foo', client_secret: 'bar') }
  let(:caller) { '+Unavailable' }
  let(:call_time) { '10.09.2014 12:15:46' }
  let(:call_extension) { '+358985646809' }

  let(:call_data) do
    '<?xml version="1.0" encoding="utf-8"?>
     <calldata>
     <calltime>' + call_time + '</calltime>
     <callerid>' + caller + '</callerid>
     <extension>' + call_extension + '</extension>
     <ivrchoise>111</ivrchoise>
     <destination>2</destination>
     </calldata>'
  end

  let(:corrupted_data) do
    '<?xml version="1.0" encoding="utf-8"?>
     <calldata>
      <calltime>30.09.2014 15:08:52</calltime>
      <callerid></callerid>
      <extension>+358985646803</extension>
      <ivrchoise>2</ivrchoise>
      <destination>258985646803</destination>
    </calldata>'
  end

  context '#create' do
    before(:each) do
      service_channel
      allow(::SmsSenderWorker).to receive(:perform_async)
    end

    it 'should parse raw POST data XML and create call task out of it' do
      post :create, call_data
      expect(::Task.count).to eq(1)
      expect(::Message.count).to eq(1)
      first_message = ::Message.first
      task          = ::Task.first
      expect(task.data['missing_calls_counter']).to eq(1)
      expect(first_message.to).to eq(call_extension)
      expect(first_message.from).to eq(caller)
      expect(first_message.description).to eq(call_time)
    end

    it 'should group calls in one task' do
      post :create, call_data
      post :create, call_data
      expect(::Task.count).to eq(1)
      expect(::Message.count).to eq(2)
      task = ::Task.first
      expect(task.data['missing_calls_counter']).to eq(2)
    end

    it 'should not create neither task no message if the XML data lacks caller number' do
      post :create, corrupted_data
      expect(::Task.count).to eq(0)
      expect(::Message.count).to eq(0)
    end

    context 'without name check' do
      before :each do
        credential.update_token('secret_token', 1000)
        ::MediaChannel::Call.update_all(name_check: false)
      end

      it 'should not call ::Fonnecta::Contacts' do
        expect_any_instance_of(::Fonnecta::Contacts).to_not receive(:search)
        post :create, call_data
      end
    end

    context 'with name check' do
      before :each do
        credential.update_token('secret_token', 1000)
        credential.save!
        ::MediaChannel::Call.update_all(name_check: true)
      end
      context 'for Unavailable caller' do
        it 'should set empty name for caller' do
          expect_any_instance_of(::Fonnecta::Contacts).to receive(:search).and_call_original
          post :create, call_data
          task = ::Task.first
          expect(task.data['caller_name']).to eq('')
        end
      end

      context 'for available caller number ' do
        let(:caller) { '+358447474120' }
        let(:response) {
          {
            'contacts' => [
              {'contactType' => 'COMPANY', 'name' => 'Foo Bar'},
              {'contactType' => 'PERSON', 'name' => 'Test Name'},
            ]
          }.to_json
        }
        before :each do
          stub_request(:get, "https://search.fonapi.fi/contacts/search?contact_type=ALL&language=fi&results_per_page=250&what=%2B358447474120").
            with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Bearer secret_token', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => response, :headers => {})
        end
        it 'should set name for caller' do
          expect_any_instance_of(::Fonnecta::Contacts).to receive(:search).and_call_original
          post :create, call_data
          task = ::Task.first
          expect(task.data['caller_name']).to eq('Test Name')
        end
      end
    end
  end
end
