# == Schema Information
#
# Table name: timelogs
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  minutes_worked :integer
#  created_at     :datetime
#  updated_at     :datetime
#  minutes_paused :integer          default(0), not null
#

class Timelog < ActiveRecord::Base

  include TimeScopes

  belongs_to :user
end
