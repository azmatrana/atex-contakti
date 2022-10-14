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

class User
  class Session < ActiveRecord::Base
    LIMIT = 10
    belongs_to :user, class_name: 'User'
    validates :user, :session_id, presence: true

    before_validation :set_unique_key

    scope :active, -> {
      where('accessed_at >= ?', 2.weeks.ago)
    }

    def set_unique_key
      self.session_id = ::SecureRandom.uuid
    end

    def accessed!(request)
      self.accessed_at = Time.current
      self.user_ip     = request.remote_ip
      self.user_agent  = request.user_agent
      save!
    end

    class << self
      def exists?(user, session_id)
        user.sessions.active.where(session_id: session_id).exists?
      end

      def fetch(user, session_id)
        if user
          user.sessions.active.where(session_id: session_id)
        else
          where(session_id: session_id)
        end.first
      end

      def activate(user)
        session = user.sessions.create!(accessed_at: ::Time.current)
        purge_old(user)
        session
      end

      def exclusive(user, session_id)
        user.sessions.where.not(session_id: session_id).delete_all
      end

      def purge_old(user)
        user.sessions.order('created_at DESC').offset(LIMIT).destroy_all
      end

      def deactivate(user, session_id = nil)
        if session_id
          fetch(user, session_id).try(:delete)
        else
          user.sessions.delete_all
        end
      end
    end
  end
end
