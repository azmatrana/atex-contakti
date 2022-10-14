require 'rails_helper'

RSpec.describe ::Fonnecta::Contacts do
  let(:company) { ::FactoryGirl.create(:company) }
  let(:credential) { ::FactoryGirl.create(:fonnecta_credential, client_id: 'foo', client_secret: 'bar') }
  let(:phone) { '+358447474120' }
  let(:fonnecta_cache) { ::FactoryGirl.create(:fonnecta_contact_cache, company: company, phone_number: phone, full_name: 'Foo Bar') }
  subject { described_class.new(company, phone).search }

  before :each do
    stub_request(:post, "https://auth.fonapi.fi/token/login").
      with(:body => {"client_id"=>"foo", "client_secret"=>"bar", "grant_type"=>"client_credentials"},
           :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => {'access_token' => 'token', 'expires_in' => 1000}.to_json, :headers => {})
  end

  context 'no fonnecta credentials' do
    it { is_expected.to eq('') }
  end
  context 'fonnecta credentials available' do
    before :each do
      credential
    end
    context '+Unavailable number' do
      let(:phone) { '+Unavailable' }
      it { is_expected.to eq('') }
    end
    context 'cache available' do
      before :each do
        fonnecta_cache
      end
      context 'and not expired' do
        it { is_expected.to eq(fonnecta_cache.full_name) }
      end
      context 'and expired' do
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
            with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Bearer token', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => response, :headers => {})
          fonnecta_cache.update_column(:updated_at, ::Time.current.advance(days: -31))
        end
        it { is_expected.to eq('Test Name') }
      end
    end
  end
end
