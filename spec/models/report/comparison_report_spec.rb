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

  def get_user_data_array(ticks, name, number)
    [ticks.select { |t| t.last == name }.first.first, number]
  end

  subject { ::FactoryGirl.create :comparison_report }

  context '#get_comparison_data' do

    let(:agent1) { ::FactoryGirl.create :agent, company_id: subject.company_id }
    let(:agent2) { ::FactoryGirl.create :agent, company_id: subject.company_id }
    let(:agent3) { ::FactoryGirl.create :agent, company_id: subject.company_id }

    let(:service_channel1) { ::FactoryGirl.create(:service_channel, company_id: subject.company_id, users: [agent1, agent2]) }
    let(:service_channel2) { ::FactoryGirl.create(:service_channel, company_id: subject.company_id, users: [agent2]) }
    let(:service_channel3) { ::FactoryGirl.create(:service_channel, company_id: subject.company_id, users: [agent2, agent3]) }

    let(:location1) { ::FactoryGirl.create(:location, company_id: subject.company_id) }
    let(:location2) { ::FactoryGirl.create(:location, company_id: subject.company_id) }


    context 'tasks count' do

      before(:each) do
        location1.service_channel_ids = [service_channel1.id, service_channel2.id, service_channel3.id]
        location2.service_channel_ids = [service_channel2.id, service_channel3.id]
        service_channel1.user_ids = [agent1.id, agent2.id]
        10.times do
          task = ::FactoryGirl.create :task, service_channel: service_channel1, media_channel: service_channel1.email_media_channel
        end
        20.times do
          task = ::FactoryGirl.create :task, service_channel: service_channel1, media_channel: service_channel1.email_media_channel
        end
        subject.users = [agent1, agent2, agent3]
        subject.starts_at = 1.day.ago
        subject.ends_at = ::Time.current
      end

      it 'should return zeroes if there are no closed tasks for each agent' do
        data = subject.get_comparison_data
        tasks_data = data[:tasks_data]
        expect(tasks_data).to include(get_user_data_array(data[:tasks_ticks], agent1.full_name, 0))
        expect(tasks_data).to include(get_user_data_array(data[:tasks_ticks], agent2.full_name, 0))
        expect(tasks_data).to include(get_user_data_array(data[:tasks_ticks], agent3.full_name, 0))
      end

      it 'should count closed tasks assigned to each agent' do
        existing_tasks = ::Task.all
        existing_tasks[0, 2].each do |task|
          task.assigned_to_user_id = agent1.id
          task.start!
          task.close!
        end
        existing_tasks[2, 5].each do |task|
          task.assigned_to_user_id = agent2.id
          task.start!
          task.close!
        end
        existing_tasks[7, 1].each do |task|
          task.assigned_to_user_id = agent3.id
          task.start!
          task.close!
        end
        subject.ends_at = ::Time.current
        data = subject.get_comparison_data
        tasks_data = data[:tasks_data]
        expect(tasks_data).to include(get_user_data_array(data[:tasks_ticks], agent1.full_name, 2))
        expect(tasks_data).to include(get_user_data_array(data[:tasks_ticks], agent2.full_name, 5))
        expect(tasks_data).to include(get_user_data_array(data[:tasks_ticks], agent3.full_name, 1))
      end

    end

    context 'turnaround time & solutions percentage' do

      before(:each) do
        location1.service_channel_ids = [service_channel1.id, service_channel2.id, service_channel3.id]
        location2.service_channel_ids = [service_channel2.id, service_channel3.id]
        service_channel1.users = [agent1, agent2]
        service_channel2.users = [agent1, agent2]
        task1 = ::FactoryGirl.create(
          :task_with_messages, messages_amount: 1, service_channel: service_channel1, media_channel: service_channel1.email_media_channel
        )
        task1.assigned_to_user_id = agent1.id
        task1.start!
        task2 = ::FactoryGirl.create(
          :task_with_messages, messages_amount: 1, service_channel: service_channel1, media_channel: service_channel1.email_media_channel
        )
        task2.assigned_to_user_id = agent2.id
        task2.start!
        ::Delorean.time_travel_to 20.minutes.from_now
        task1.close!
        ::Delorean.time_travel_to 10.minutes.from_now
        task2.close!
        task3 = ::FactoryGirl.create(
          :task_with_messages, messages_amount: 1, service_channel: service_channel2, media_channel: service_channel2.web_form_media_channel
        )
        task3.assigned_to_user_id = agent1.id
        task3.start!
        ::Delorean.time_travel_to 5.minutes.from_now
        task3.close!
        subject.users = [agent1, agent2]
        subject.starts_at = 1.day.ago
        subject.ends_at = ::Time.current
      end

      after(:each) do
        ::Delorean.back_to_the_present
      end

      it 'should count turnaround time for each agent' do
        data = subject.get_comparison_data
        expect(data[:tasks_turnaround_data]).to include get_user_data_array(data[:tasks_turnaround_ticks], agent1.full_name, 12) # ((20 + 5) / 2).floor
        expect(data[:tasks_turnaround_data]).to include get_user_data_array(data[:tasks_turnaround_ticks], agent2.full_name, 30)
      end

      it 'should not count call tasks in turnaround' do
        service_channel2.users = [agent1, agent2]
        call_task = ::FactoryGirl.create(
          :task_with_messages, messages_amount: 1, service_channel: service_channel2, media_channel: service_channel2.call_media_channel
        )
        ::Delorean.time_travel_to 5.minutes.from_now
        call_task.close!
        data = subject.get_comparison_data
        expect(data[:tasks_turnaround_data]).to include get_user_data_array(data[:tasks_turnaround_ticks], agent1.full_name, 12)
      end

      it 'should correctly count solutions percentage' do
        data = subject.get_comparison_data
        expect(data[:solutions_perc_data]).to include get_user_data_array(data[:solutions_perc_ticks], agent1.full_name, 100)
        expect(data[:solutions_perc_data]).to include get_user_data_array(data[:solutions_perc_ticks], agent2.full_name, 100)
      end

      it 'should correctly count solutions percentage after some unsolved tasks has been added' do
        service_channel2.users = [agent1, agent2]
        2.times do
          task = ::FactoryGirl.create(
            :task_with_messages, messages_amount: 1, service_channel: service_channel2, media_channel: service_channel2.web_form_media_channel
          )
          task.assigned_to_user_id = agent1.id
          task.start!
        end
        subject.ends_at = ::Time.current
        data = subject.get_comparison_data
        expect(data[:solutions_perc_data]).to include get_user_data_array(data[:solutions_perc_ticks], agent1.full_name, 50)
      end

    end

    context 'pauses percentage' do

      before(:each) do
        ::FactoryGirl.create(:timelog, minutes_worked: 120, minutes_paused: 60, created_at: 2.hours.ago, user: agent1)
        ::Delorean.time_travel_to 1.day.from_now
        ::FactoryGirl.create(:timelog, minutes_worked: 120, minutes_paused: 30, created_at: 2.hours.ago, user: agent1)
        subject.users = [agent1]
        subject.starts_at = 2.days.ago
        subject.ends_at = ::Time.current
      end

      after(:each) do
        ::Delorean.back_to_the_present
      end

      it 'should count pauses percentage' do
        data = subject.get_comparison_data
        expect(data[:pauses_data].first).to eq([1, 37.5]) # 37.5 = (50 + 25) / 2
      end

      # TODO: known issue: pauses percentage is not bounded by report date range
    end
  end
end
