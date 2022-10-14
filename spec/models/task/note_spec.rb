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

require 'rails_helper'

RSpec.describe Task::Note, :type => :model do
  it { is_expected.to belong_to(:task) }
  it { is_expected.to validate_presence_of(:task_id) }
  it { is_expected.to validate_presence_of(:body) }
  it { is_expected.to validate_uniqueness_of(:task_id) }
end
