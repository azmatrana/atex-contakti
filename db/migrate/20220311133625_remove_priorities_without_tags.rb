class RemovePrioritiesWithoutTags < ActiveRecord::Migration
  def change
    Company.all.each do |company|
      company_tags_ids = company.skills.pluck(:id)
      company_priorities_othen_than_tags = Priority.where(company_id: company.id).where.not(tag_id: company_tags_ids)
      company_priorities_othen_than_tags.destroy_all
    end
  end
end
