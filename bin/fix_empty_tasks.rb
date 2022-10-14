#!/usr/bin/env ruby

# This script can be used to destroy invalidly added tasks from the system that
# have no messages assigned to them. This can break the UI in some situations.
#
# Usage:
# RAILS_ENV=env bundle exec ruby bin/fix_empty_tasks.rb "Company Name" "Service Channel Name"
#
# Example:
# RAILS_ENV=testing bundle exec ruby bin/fix_empty_tasks.rb "Desk" "DS-tuki"

require File.expand_path('../../config/environment', __FILE__)

company_name = ARGV[0]
channel_name = ARGV[1]
media_channel_type = "MediaChannel::Email"
iteration_limit = 100 # How many tasks to process at once

company = Company.find_by(name: company_name)
unless company
  puts "Company not found: #{company_name}"
  exit
end

channel = company.service_channels.find_by(name: channel_name)
unless channel
  puts "Channel not found: #{channel_name}"
  exit
end

media_channel = channel.media_channels.find_by(type: media_channel_type)
unless media_channel
  puts "Media channel not found: #{media_channel_type}"
  exit
end

# Find tasks from the given channel and type without any messages
while true do
  tasks = company.tasks
    .joins(:service_channel)
    .joins(:media_channel)
    .joins("LEFT JOIN messages ON messages.task_id = tasks.id")
    .where(service_channel: channel, media_channel: media_channel)
    .group("tasks.id, messages.task_id")
    .having("COUNT(messages.id) = 0")
    .order("tasks.id")
    .limit(iteration_limit)

  destroyed = tasks.pluck(:id)
  if destroyed.count == 0
    break
  end

  # Destroying disabled
  tasks.destroy_all

  puts "Following tasks were destroyed:"
  puts destroyed.join(', ')
end

puts "Fixing empty tasks finished."
