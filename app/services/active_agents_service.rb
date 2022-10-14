class ActiveAgentsService

  def initialize(company)
    @company = company
  end

  def for_date(date)
    active_users       = ::Company.where(id: @company.id)
                                  .joins(users: :timelogs)
                                  .select('count(DISTINCT users.id) as count', 'companies.id as company_id')
                                  .group('companies.id')
    beginning_of_month = date.to_time.beginning_of_month
    end_of_month       = date.to_time.end_of_month
    res                = active_users.where('timelogs.created_at BETWEEN ? AND ?', beginning_of_month, end_of_month).first
    res ? res['count'] : 0
  end

  class << self
    def current_and_last_month
      active_users            = ::Company.joins(users: :timelogs)
                                         .select('count(DISTINCT users.id) as count', 'companies.id as company_id')
                                         .group('companies.id')
      previous_month          = ::Time.current.advance(months: -1)
      beginning_of_month      = previous_month.to_time.beginning_of_month
      end_of_month            = previous_month.to_time.end_of_month
      active_users_last_month = active_users.where('timelogs.created_at BETWEEN ? AND ?', beginning_of_month, end_of_month)
      [active_users, active_users_last_month].map do |users|
        ::Hash[*users.map { |x| [x['company_id'], x['count']] }.flatten]
      end
    end
  end

end