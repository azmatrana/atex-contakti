module TimeScopes
  def self.included(base)
    base.class_eval do
      scope :for_period, ->(starts_at,ends_at) { where("#{self.table_name}.created_at BETWEEN ? AND ?",starts_at,ends_at) }
      scope :for_period_updated_at,
            ->(starts_at, ends_at) {
              where("#{self.table_name}.updated_at BETWEEN ? AND ?", starts_at, ends_at)
            }
    end
  end
end
