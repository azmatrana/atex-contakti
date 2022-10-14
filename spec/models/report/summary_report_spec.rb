# == Schema Information
#
# Table name: reports
#
#  id                  :integer          not null, primary key
#  title               :string(100)      default(""), not null
#  kind                :string(20)       default(""), not null
#  starts_at           :datetime
#  ends_at             :datetime
#  company_id          :integer
#  author_id           :integer
#  created_at          :datetime
#  updated_at          :datetime
#  send_to_emails      :string(500)      default(""), not null
#  scheduled           :string(255)      default(""), not null
#  last_sent_at        :datetime
#  media_channel_types :text             default([]), is an Array
#

require 'rails_helper'

describe Report do

  it 'should have a valid factory' do
    expect(::FactoryGirl.build(:report)).to be_valid
  end

  context '#screenshot_for_period' do

    it 'should return screenshot file' do
      start_date = ::Time.at(0)
      end_date = start_date + 10.days
      screenshot = subject.screenshot_for_period(start_date, end_date)
      expect(screenshot.basename.to_s).to eq("#{subject.id}_19700101_19700111.png")
    end

  end

  context 'scheduled scope' do

    it 'should return only reports with non-empty scheduled and send_to_emails' do
      report1 = ::FactoryGirl.create :summary_report
      report2 = ::FactoryGirl.create :summary_report, scheduled: :daily, send_to_emails: ''
      report3 = ::FactoryGirl.create :comparison_report
      report4 = ::FactoryGirl.create :comparison_report, scheduled: :weekly, send_to_emails: 'bla@bla.com'
      results = described_class.scheduled
      expect(results.count).to equal(1)
      expect(results.first.id).to equal(report4.id)
    end

  end

  context '#get_summary_data' do

    subject { ::FactoryGirl.create :summary_report }

    let(:agent1) { ::FactoryGirl.create :agent, company_id: subject.company_id }
    let(:agent2) { ::FactoryGirl.create :agent, company_id: subject.company_id }

    let(:service_channel1) { ::FactoryGirl.create(:service_channel, company_id: subject.company_id) }
    let(:service_channel2) { ::FactoryGirl.create(:service_channel, company_id: subject.company_id) }
    let(:service_channel3) { ::FactoryGirl.create(:service_channel, company_id: subject.company_id) }

    let(:location1) { ::FactoryGirl.create(:location, company_id: subject.company_id) }
    let(:location2) { ::FactoryGirl.create(:location, company_id: subject.company_id) }

    context 'counters' do

      before(:each) do
        location1.service_channel_ids = [service_channel1.id, service_channel2.id, service_channel3.id]
        location2.service_channel_ids = [service_channel2.id, service_channel3.id]
        service_channel1.user_ids = [agent1.id]
        10.times do
          task = ::FactoryGirl.create :task, service_channel: service_channel1, media_channel: service_channel1.email_media_channel
        end
        5.times do
          task = ::FactoryGirl.create :task, service_channel: service_channel1, media_channel: service_channel1.web_form_media_channel
        end
        service_channel2.user_ids = [agent2.id]
        15.times do
          task = ::FactoryGirl.create :task, service_channel: service_channel2, media_channel: service_channel2.email_media_channel, state: :open
        end
        service_channel3.user_ids = [agent1.id, agent2.id]
        20.times do
          task = ::FactoryGirl.create :task, service_channel: service_channel3, media_channel: service_channel3.email_media_channel, state: :ready
        end
        7.times do
          task = ::FactoryGirl.create :task, service_channel: service_channel3, media_channel: service_channel3.call_media_channel, state: :new
        end
        3.times do
          task = ::FactoryGirl.create(
            :task, service_channel: service_channel3, media_channel: service_channel3.call_media_channel, state: :ready, result: :positive)
        end
        4.times do
          task = ::FactoryGirl.create(
            :task, service_channel: service_channel3, media_channel: service_channel3.call_media_channel, state: :ready, result: :negative)
        end
        task = ::FactoryGirl.create(
          :task, service_channel: service_channel3, media_channel: service_channel3.call_media_channel, state: :ready, result: :neutral)
        subject.location_ids = [location1.id, location2.id]
        subject.service_channel_ids = [service_channel1.id, service_channel2.id, service_channel3.id]
        subject.media_channel_types = %w[email web_form call]
        subject.user_ids = [agent1.id, agent2.id]
        subject.ends_at = ::Time.current + 1.day
      end

      it 'should correctly count total number of tasks' do
        data = subject.get_summary_data
        expect(data[:total_tasks_count]).to eq(65)
        expect(data[:tasks_count][:email_channel][:total]).to eq(45)
        expect(data[:tasks_count][:web_form_channel][:total]).to eq(5)
        expect(data[:tasks_count][:call_channel][:total]).to eq(15)
      end

      it 'should correctly count tasks by task state' do
        data = subject.get_summary_data
        expect(data[:tasks_count][:email_channel][:new]).to eq(10)
        expect(data[:tasks_count][:email_channel][:open]).to eq(15)
        expect(data[:tasks_count][:email_channel][:waiting]).to eq(0)
        expect(data[:tasks_count][:email_channel][:ready]).to eq(20)

        expect(data[:tasks_count][:web_form_channel][:new]).to eq(5)
        expect(data[:tasks_count][:web_form_channel][:open]).to eq(0)
        expect(data[:tasks_count][:web_form_channel][:waiting]).to eq(0)
        expect(data[:tasks_count][:web_form_channel][:ready]).to eq(0)
      end

      it 'should correctly count call task results' do
        data = subject.get_summary_data
        expect(data[:tasks_count][:call_channel][:unsolved]).to eq(7)
        expect(data[:tasks_count][:call_channel][:positive]).to eq(3)
        expect(data[:tasks_count][:call_channel][:negative]).to eq(4)
        expect(data[:tasks_count][:call_channel][:neutral]).to eq(1)
        expect(data[:tasks_count][:call_channel][:ready]).to eq(8)
      end

      it 'should correctly count tasks by service channel' do
        data = subject.get_summary_data
        ticks = data[:service_channel_ticks]
        [ [15, service_channel1], [15, service_channel2], [35, service_channel3] ].each do |tuple|
          tasks_number, service_channel = tuple
          # FIX ME (now location data not included data for each localtion)
          # expect(data[:service_channel_data]).to include(
          #   [tasks_number, ticks.select { |t| t.last == service_channel.name }.first.first]
          # )
        end
      end

      it 'should correctly count tasks by location' do
        # data[:location_data]
        # [
        #   {:label => "New", :data => [[7, 0], [22, 1]]},
        #   {:label => "Open", :data => [[15, 0], [15, 1]]},
        #   {:label => "Waiting", :data => [[0, 0], [0, 1]]},
        #   {:label => "Ready", :data => [[28, 0], [28, 1]]}
        # ]

        data = subject.get_summary_data
        ticks = data[:location_ticks]
        [location1, location2].each do |location|
          # FIX ME (now location data not included data for each localtion)
          # expect(data[:location_data]).to include(
          #   [location.service_channels.map { |s| s.tasks.count }.reduce(:+), ticks.select { |t| t.last == location.name }.first.first]
          # )
        end
      end
    end

    context 'average processing time & waiting period' do
      before(:each) do
        location1.service_channel_ids = [service_channel1.id]
        service_channel1.user_ids = [agent1.id]
        task1 = ::FactoryGirl.create :task, service_channel: service_channel1, media_channel: service_channel1.email_media_channel
        ::FactoryGirl.create(:message, task_id: task1.id)
        task2 = ::FactoryGirl.create :task, service_channel: service_channel1, media_channel: service_channel1.email_media_channel
        ::FactoryGirl.create(:message, task_id: task2.id)

        ::Delorean.time_travel_to(1.hour.from_now)
        task1.start!
        ::Delorean.time_travel_to(30.minutes.from_now) # agent writes the reply
        ::FactoryGirl.create(:message, number: 2, task_id: task1.id)
        task1.close!

        ::Delorean.time_travel_to(30.minutes.from_now) # agent drinks coffee
        task2.start!
        ::Delorean.time_travel_to(20.minutes.from_now) # agent writes the reply
        ::FactoryGirl.create(:message, number: 2, task_id: task2.id)
        task2.close!

        ::Delorean.time_travel_to(5.minutes.from_now) # agent edits the report
        subject.location_ids = [location1.id]
        subject.service_channel_ids = [service_channel1.id]
        subject.media_channel_types = %w[email web_form]
        subject.user_ids = [agent1.id]
        subject.starts_at = 1.day.ago
        subject.ends_at = ::Time.current
      end

      after(:each) do
        ::Delorean.back_to_the_present
      end

      it 'should calculate avg processing time for email and web_form tasks' do
        data = subject.get_summary_data
        expect(data[:tasks_count][:email_channel][:avg_processing_time]).to eq('25m')
      end

      it 'should not be affected by non-closed tasks' do
        service_channel1.user_ids = [agent1.id]
        10.times do
          task = ::FactoryGirl.create :task, service_channel: service_channel1, media_channel: service_channel1.email_media_channel
        end
        subject.ends_at = ::Time.current
        data = subject.get_summary_data
        expect(data[:tasks_count][:email_channel][:avg_processing_time]).to eq('25m')
      end

      it 'should calculate waiting period for email and web form tasks' do
        data = subject.get_summary_data
        expect(data[:tasks_count][:email_channel][:avg_waiting_period]).to eq('1h 55m') # (90m + 140m) / 2
      end

    end

    context 'peak times' do

      let(:current_time_zone) { ::Time.zone }

      before(:each) do
        ::Time.zone = subject.company.time_zone # time_zone offset = +2
        location1.service_channel_ids = [service_channel1.id, service_channel2.id, service_channel3.id]
        location2.service_channel_ids = [service_channel2.id, service_channel3.id]
        ::Delorean.time_travel_to ::DateTime.parse('1/1/1970') # 00:00
        service_channel1.user_ids = [agent1.id, agent2.id]
        10.times do
          task = ::FactoryGirl.create(
            :task_with_messages, messages_amount: 1, service_channel: service_channel1, media_channel: service_channel1.email_media_channel
          )
        end
        5.times do
          task = ::FactoryGirl.create :task_with_messages, messages_amount: 1, service_channel: service_channel1, media_channel: service_channel1.web_form_media_channel
        end
        ::Delorean.time_travel_to 6.hours.from_now # 06:00
        service_channel2.user_ids = [agent1.id, agent2.id]
        8.times do
          task = ::FactoryGirl.create :task_with_messages, messages_amount: 1, service_channel: service_channel2, media_channel: service_channel2.call_media_channel
        end
        5.times do
          task = ::FactoryGirl.create :task_with_messages, messages_amount: 1, service_channel: service_channel1, media_channel: service_channel1.web_form_media_channel
        end
        ::Delorean.time_travel_to 5.hours.from_now # 11:00
        service_channel3.user_ids = [agent1.id]
        10.times do
          task = ::FactoryGirl.create :task_with_messages, messages_amount: 1, service_channel: service_channel3, media_channel: service_channel3.email_media_channel, state: :ready
        end
        11.times do
          task = ::FactoryGirl.create :task_with_messages, messages_amount: 1, service_channel: service_channel2, media_channel: service_channel2.call_media_channel
        end
        ::Delorean.time_travel_to 8.hours.from_now # 19:00
        task = ::FactoryGirl.create :task_with_messages, messages_amount: 1, service_channel: service_channel3, media_channel: service_channel3.email_media_channel
        subject.location_ids = [location1.id, location2.id]
        subject.service_channel_ids = [service_channel1.id, service_channel2.id, service_channel3.id]
        subject.media_channel_types = %w[email web_form call]
        subject.user_ids = [agent1.id, agent2.id]
        subject.starts_at = 1.day.ago
        subject.ends_at = ::Time.current
      end

      after(:each) do
        ::Delorean.back_to_the_present
        ::Time.zone = current_time_zone
      end

      it 'should correctly calculate peak times for email channel' do
        data = subject.get_summary_data
        expect(data[:peak_times][:email_channel]).to eq([ [0 + 2, 10], [11 + 2, 10], [19 + 2, 1] ])
      end

      it 'should correctly calculate peak times for web_form channel' do
        data = subject.get_summary_data
        expect(data[:peak_times][:web_form_channel]).to eq([ [0 + 2, 5], [6 + 2, 5] ])
      end

      it 'should correctly calculate peak times for call channel' do
        data = subject.get_summary_data
        expect(data[:peak_times][:call_channel]).to eq([ [6 + 2, 8], [11 + 2, 11] ])
      end

      it 'should calculate peak time hours based on current timezone' do
        ::Time.zone = 'UTC'
        data = subject.get_summary_data
        expect(data[:peak_times][:call_channel]).to eq([ [6, 8], [11, 11] ])
      end

      it 'should calculate peak times hours for timezones with negative offsets' do
        ::Time.zone = 'Hawaii' # GMT-10:00
        data = subject.get_summary_data
        expect(data[:peak_times][:call_channel]).to eq([ [1, 11], [20, 8] ])
      end

      it 'should sort hours in increasing order for timezones with large positive offset' do
        ::Time.zone = 'Hong Kong' # GMT+8:00
        data = subject.get_summary_data
        expect(data[:peak_times][:email_channel]).to eq([ [3, 1], [8, 10], [19, 10] ])
      end

      it 'should calculate peak times only for closed tasks if "closed" scope is selected' do
        subject.report_scope = 'closed'
        data = subject.get_summary_data
        expect(data[:peak_times][:email_channel]).to eq([ [13, 10] ])
      end

    end

  end

end
