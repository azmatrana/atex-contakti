# == Schema Information
#
# Table name: fonnecta_credentials
#
#  id              :integer          not null, primary key
#  client_id       :string(255)      not null
#  client_secret   :string(255)      not null
#  token           :string(255)
#  token_taken_at  :datetime
#  token_expire_in :integer
#  created_at      :datetime
#  updated_at      :datetime
#

require 'rails_helper'

RSpec.describe Fonnecta::Credential, :type => :model do
  let(:credential) { ::FactoryGirl.create(:fonnecta_credential, client_id: 'foo', client_secret: 'bar') }
  it { is_expected.to validate_presence_of(:client_id) }
  it { is_expected.to validate_presence_of(:client_secret) }

  context '#check_credentials_changings' do
    before :each do
      credential
    end
    it 'should call on save' do
      expect(credential).to receive(:check_credentials_changings)
      credential.save!
    end
    it 'should not call on validation' do
      expect(credential).to_not receive(:check_credentials_changings)
      credential.valid?
    end
    it 'should nullify token, token_taken_at and token_expire_in' do
      credential.update_token('test_token', 12345555)
      credential.save!
      expect(credential.token).to eq('test_token')
      credential.client_id = 'wow'
      credential.save!
      expect(credential.token).to be_nil
      expect(credential.token_taken_at).to be_nil
      expect(credential.token_expire_in).to be_nil
    end
  end

  context '#update_token' do
    before :each do
      credential
    end
    it 'should set token, token_taken_at and token_expire_in' do
      time = ::Time.now
      allow(::Time).to receive(:current).and_return(time)
      credential.update_token('test_token', 12345)
      expect(credential.token).to eq('test_token')
      expect(credential.token_taken_at).to be_within(0).of(time)
      expect(credential.token_expire_in).to eq(12345)
    end
  end

  context '#token_usable?' do
    before :each do
      credential
    end
    subject { credential.token_usable? }

    context 'token empty' do
      before :each do
        credential.update_column(:token, nil)
      end
      it { is_expected.to be_falsey }
    end

    context 'will expire in future' do
      before :each do
        credential.update_columns(token: 'test_token', token_taken_at: ::Time.current, token_expire_in: 5.minute)
      end
      it { is_expected.to be_truthy }
    end

    context 'expired in past' do
      before :each do
        credential.update_columns(token: 'test_token', token_taken_at: ::Time.current.advance(minutes: -5), token_expire_in: 5.minute)
      end
      it { is_expected.to be_falsey }
    end
  end
end
