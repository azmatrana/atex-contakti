# == Schema Information
#
# Table name: task_notes
#
#  id         :integer          not null, primary key
#  task_id    :integer          not null
#  body       :text
#  created_at :datetime
#  updated_at :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :task_note, :class => 'Task::Note' do
    task_id 1
    body "MyText"
  end
end
