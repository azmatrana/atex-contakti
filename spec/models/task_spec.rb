# == Schema Information
#
# Table name: tasks
#
#  id                  :integer          not null, primary key
#  state               :string(100)      default(""), not null
#  service_channel_id  :integer
#  created_at          :datetime
#  updated_at          :datetime
#  uuid                :uuid
#  minutes_spent       :integer          default(0), not null
#  assigned_to_user_id :integer
#  last_opened_at      :datetime
#  opened_at           :datetime
#  turnaround_time     :integer          default(0), not null
#  media_channel_id    :integer
#  deleted_at          :datetime
#  assigned_at         :datetime
#  result              :string(20)       default(""), not null
#  data                :json             default({}), not null
#  created_by_user_id  :integer
#
# Indexes
#
#  index_tasks_on_deleted_at  (deleted_at)
#

require 'rails_helper'

RSpec.describe Task, type: :model do

  it { should belong_to(:service_channel) }
  it { should belong_to(:media_channel) }
  it { should belong_to(:agent).class_name('User').with_foreign_key('assigned_to_user_id') }
  it { should have_one(:note).class_name('Task::Note').autosave(true) }
  it { should have_many(:messages).order('created_at DESC').dependent(:destroy) }
  it { should delegate_method(:users).to(:media_channel) }

  context 'scopes' do
    let(:service_channel) { ::FactoryGirl.create(:service_channel) }
    let(:email) { service_channel.email_media_channel }
    let(:call) { service_channel.call_media_channel }
    let(:web_form) { service_channel.web_form_media_channel }
    let(:emails) { ::FactoryGirl.create_list(:task, 2, service_channel: service_channel, media_channel: email) }
    let(:calls) { ::FactoryGirl.create_list(:task, 3, service_channel: service_channel, media_channel: call) }
    let(:web_forms) { ::FactoryGirl.create_list(:task, 3, service_channel: service_channel, media_channel: web_form) }

    context 'media channels' do
      before :each do
        emails
        calls
        web_forms
      end
      context 'email_channel' do
        subject { described_class.email_channel.to_a.sort_by(&:id) }
        it { is_expected.to eq(emails.sort_by(&:id)) }
      end
      context 'web_form_channel' do
        subject { described_class.web_form_channel.to_a.sort_by(&:id) }
        it { is_expected.to eq(web_forms.sort_by(&:id)) }
      end
      context 'call_channel' do
        subject { described_class.call_channel.to_a.sort_by(&:id) }
        it { is_expected.to eq(calls.sort_by(&:id)) }
      end
    end

    context 'for_period' do
      before :each do
        ::Delorean.time_travel_to(4.days.ago)
        emails
        Delorean.back_to_the_present
        calls
        ::Delorean.time_travel_to(6.days.ago)
        web_forms
        Delorean.back_to_the_present
      end
      let(:start_at) { ::Time.current.advance(days: -5) }
      let(:end_at) { ::Time.current.advance(days: -3) }
      subject { described_class.for_period(start_at, end_at).to_a.sort_by(&:id) }
      it { is_expected.to eq(emails.sort_by(&:id)) }
    end
  end

  context 'instance' do
    subject { ::FactoryGirl.create :task }

    context '#minutes_spent' do
      it 'should count current minutes spent' do
        subject.start!
        ::Delorean.time_travel_to(2.hours.from_now) do
          expect(subject.current_minutes_spent).to eq(120)
        end
      end

      it 'should include previous minutes spent when returning task back to open from "waiting" state' do
        subject.start!
        ::Delorean.time_travel_to(1.hour.from_now)
        subject.pause!
        ::Delorean.time_travel_to(1.day.from_now)
        subject.start!
        expect(subject.minutes_spent).to eq(60)
        ::Delorean.time_travel_to(25.minutes.from_now)
        expect(subject.current_minutes_spent).to eq(25)
        expect(subject.total_minutes_spent).to eq(85)
        ::Delorean.back_to_the_present
      end

      it 'should set the time spent after going to "ready" state' do
        subject.start!
        ::Delorean.time_travel_to(1.hour.from_now)
        subject.pause!
        ::Delorean.time_travel_to(2.days.from_now)
        subject.start!
        ::Delorean.time_travel_to(10.minutes.from_now)
        subject.close!
        expect(subject.minutes_spent).to eq(70)
        ::Delorean.back_to_the_present
      end

      it 'should correctly set "last_opened_at" field' do
        subject.start!
        expect(subject.last_opened_at).to be
      end

      it 'should correctly count minutes spent when closing the task after it was opened' do
        subject.start!
        ::Delorean.time_travel_to(10.minutes.from_now) do
          subject.close!
          expect(subject.reload.minutes_spent).to eq(10)
        end
      end
    end

    context '#turnaround_time' do
      it 'should set turnaround time on task close' do
        subject.start!
        ::Delorean.time_travel_to(2.hours.from_now) do
          subject.close!
          expect(subject.turnaround_time).to eq(120)
        end
      end
    end

    context '#minutes_till_alert' do
      # service channel red alert limit = 1 day 6 hours, yellow alert limit = 1 day
      it 'should calculate minutes till red alert' do
        subject.start!
        ::Delorean.time_travel_to(1.day.from_now) do
          expect(subject.minutes_till_red_alert).to eq(6 * 60)
        end
      end

      it 'should return negative number if the time spent on task is greater that red alert limit' do
        subject.start!
        ::Delorean.time_travel_to(2.days.from_now) do
          expect(subject.minutes_till_red_alert).to eq(-18 * 60)
        end
      end

      it 'should calculate yellow alert limit' do
        subject.start!
        ::Delorean.time_travel_to(23.hours.from_now) do
          # FIX ME!
          # expect(subject.minutes_till_alert 'yellow').to eq(60)
        end
      end

      it 'should start counting alert limits from task creation date' do
        subject
        ::Delorean.time_travel_to(1.hour.from_now)
        subject.start!
        ::Delorean.time_travel_to(1.day.from_now) do
          # FIX ME!
          # expect(subject.minutes_till_alert 'yellow').to eq(-60)
          expect(subject.minutes_till_alert 'red').to eq(5 * 60)
        end
        ::Delorean.back_to_the_present
      end

      it 'should correctly calculate minutes in case of decimal alert limit hours' do
        subject.service_channel.red_alert_hours = 6.5
        subject.start!
        ::Delorean.time_travel_to(1.day.from_now) do
          expect(subject.minutes_till_red_alert).to eq(6.5 * 60)
        end
      end
    end

    context 'clear_result' do
      it 'should set result to empty string after task open' do
        subject.start!
        subject.result = 'positive'
        subject.close!
        expect(subject).to be_positive
        subject.restart!
        subject.open!
        expect(subject.result).to be_empty
      end
    end

    context '#push_task_to_browser' do
      it 'should enqueue background job' do
        subject.push_task_to_browser
        expect(::DanthesPushWorker).to have_enqueued_job(subject.class.name, subject.id)
      end
    end
  end

  context 'after_commit', with_after_commit: true do
    context 'on create' do
      subject { ::FactoryGirl.build(:task) }
      context 'push_task_to_browser' do
        it 'should not be called' do
          expect(subject).to_not receive(:push_task_to_browser)
          subject.save!
        end
      end
    end

    context 'on update' do
      context 'push_task_to_browser' do
        subject { ::FactoryGirl.create(:task) }
        context 'push_task_to_browser' do
          it 'should not be called' do
            subject.touch
            expect(subject).to receive(:push_task_to_browser)
            subject.save!
          end
        end
      end
    end
  end
end
