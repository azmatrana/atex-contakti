# == Schema Information
#
# Table name: task_versions
#
#  id             :integer          not null, primary key
#  item_type      :string(255)      not null
#  item_id        :integer          not null
#  event          :string(255)      not null
#  whodunnit      :string(255)
#  object         :text
#  created_at     :datetime
#  object_changes :text
#
# Indexes
#
#  index_task_versions_on_item_type_and_item_id  (item_type,item_id)
#

class TaskVersion < PaperTrail::Version
  self.table_name = :task_versions
end
