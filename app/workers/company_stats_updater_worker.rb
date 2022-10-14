class CompanyStatsUpdaterWorker
  include ::Sidekiq::Worker
  sidekiq_options unique: true, retry: false

  def perform
    ::Company.find_each do |company|
      stat = company.current_stat
      stat.active_agents = ::ActiveAgentsService.new(company).for_date(::Date.today)
      stat.save!
    end
  end
end
