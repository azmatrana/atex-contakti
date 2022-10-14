# == Schema Information
#
# Table name: user_sessions
#
#  id          :integer          not null, primary key
#  session_id  :uuid             not null
#  user_id     :integer          not null
#  user_ip     :string(255)
#  user_agent  :string(255)
#  accessed_at :datetime
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_user_sessions_on_session_id              (session_id) UNIQUE
#  index_user_sessions_on_user_id                 (user_id)
#  index_user_sessions_on_user_id_and_session_id  (user_id,session_id)
#

require 'spec_helper'

describe User::Session do
  pending "add some examples to (or delete) #{__FILE__}"
end
