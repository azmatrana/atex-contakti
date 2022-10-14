require 'rails_helper'

describe UsersController, type: :controller do

  let(:user) { FactoryGirl.create :agent, is_online: true, is_working: true }

  before(:each) do
    sign_in user
  end

  context '#change_online_status' do

    it 'should change user online status to offline' do
      put :change_online_status, online: 'false'
      user.reload
      expect(user.is_online).to be_falsey
    end

    it 'should update "went_offline_at" field when going offline' do
      current_time = ::Time.current
      allow(::Time). to receive(:current).and_return(current_time)
      put :change_online_status, online: 'false'
      user.reload
      expect(user.went_offline_at.to_i).to eq(current_time.to_i)
    end

    it 'should set timelog minutes_paused when the user goes back online' do
      last_timelog = user.timelogs.create!
      put :change_online_status, online: 'false'
      expect(user.is_online).to be_falsey
      ::Delorean.time_travel_to(30.minutes.from_now) do
        put :change_online_status, online: 'true'
        expect(user.is_online).to be_truthy
        expect(last_timelog.reload.minutes_paused).to eq(30)
      end
    end

    it 'should increment timelog minutes_paused when the user goes back online' do
      user.timelogs.create!(minutes_paused: 20)
      user.update_attributes(is_online: false, went_offline_at: 5.minutes.ago)
      ::Delorean.time_travel_to(30.minutes.from_now) do
        put :change_online_status, online: 'true'
        expect(user.timelogs.last.minutes_paused).to eq(55)
      end
    end
  end
end
