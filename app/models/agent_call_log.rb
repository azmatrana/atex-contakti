class AgentCallLog < ActiveRecord::Base

  include TimeScopes
  belongs_to :agent, class_name: 'User', foreign_key: 'agent_id'
  belongs_to :callable, polymorphic: true
  # after_commit :remove_same_calls_from_other_agents, on: :update
  # after_save :remove_same_calls_from_other_agents
  # after_commit :remove_same_calls_from_other_agents, on: :create
  before_validation :set_call_times

  after_commit :call_update_same_call_worker, on: [:create, :update]
  after_commit :call_campaign_update, on: [:create, :update]
  scope :visible, -> { where(visible: true).not_continued_calls }

  scope :not_continued_calls, -> { where.not(call_status: ['resumed', 'ringing', 'holding']) }

  scope :answered,   -> { where(call_status: ['answered', 'ended']) }
  scope :unanswered, -> { where(call_status: ['missed']) }
  scope :incoming, -> { where(flow: 'incoming') }
  scope :not_internal_calls, -> { where("length(agent_call_logs.clid) > 5") }
  scope :for_reports, -> { incoming.not_internal_calls }

  def self.push_to_browser(current_user_id=nil)
    if current_user_id.present?
      ::Danthes.publish_to "/agent_call_logs/#{current_user_id}", AgentCallLog.visible.where(agent_id: current_user_id).as_json
    end
  end

  def remove_same_calls_from_other_agents

    # If the call is not answered and an unanswered call is left, which the agent then calls back,
    # then that call must be removed from the call list of all agents from the missed calls.

    # if the missed call from the same number is redialled and his call is answered,
    # then the previous missed call must be dropped from the missed calls.

    if self.clid.length > 5
      # puts "=========================\n"*2

      agent_ids = []
      same_calls = AgentCallLog.visible.where(uri: self.uri, flow: 'incoming', call_status: 'missed').where.not(id: self.id)#.where.not(call_status: 'ringing')
      if same_calls.length > 0 && ( (self.flow == 'outgoing') || (self.flow == 'incoming' && (self.call_status == 'answered')) )
        agent_ids = same_calls.pluck(:agent_id).uniq
        same_calls.destroy_all

      end

      if ( (self.flow == 'incoming' && self.call_status == 'answered') )
        same_calls = AgentCallLog.visible.where(uri: self.uri, flow: 'incoming', call_status: ['missed']).where.not(id: self.id)#.where.not(call_status: 'ringing')
        if same_calls.length > 0
          agent_ids = agent_ids + same_calls.pluck(:agent_id).uniq
          same_calls.destroy_all
        end
      end

      if agent_ids.length > 0
        agent_ids.each do |_agent_id|
          AgentCallLog.push_to_browser(_agent_id)
        end
      end

    end
  end

  def call_campaign_update
    if (self.callable && self.callable.class.name == 'CampaignItem')
      self.callable.push_to_browser_refresh
    end
  end

  def call_update_same_call_worker
    ::AgentSameCallUpdaterWorker.perform_async(self.id)
  end


  def self.average_call_wait_seconds
    _calls = self.pluck(:call_ring_wait_seconds).compact
    if _calls.length > 0
      return _calls.sum / _calls.length
    else
      return 0
    end

  end

  def self.average_call_duration_seconds
    _calls = self.pluck(:call_duration_seconds).compact
    if _calls.length > 0
      return (_calls.sum) / _calls.length
    else
      return 0
    end
  end

  def set_call_times
    if self.call_ring_start.to_i > 0 && self.call_ring_stop.to_i > 0
      self.call_ring_wait_seconds = self.call_ring_stop - self.call_ring_start
    end

    if self.call_start.to_i > 0 && self.call_stop.to_i > 0
      self.call_duration_seconds = self.call_stop - self.call_start
      self.call_duration_seconds = call_duration_seconds/1000
    end
  end

end

