class FixCollectingCompanyStats < ActiveRecord::Migration
  def up
    next_month = ::Date.today.end_of_month + 1.day
    ::Company.find_each do |company|
      date = company.created_at.to_date.end_of_month
      while date < next_month
        my_stat = company.stats.where(date: date.beginning_of_month).first_or_initialize
        my_stat.active_agents = ::ActiveAgentsService.new(company).for_date(date)
        my_stat.save!
        date = date.next_month
      end
    end
  end
end
