class CustomerSerializer < ActiveModel::Serializer
  attributes *(Customer.attribute_names.map(&:to_sym))
  has_one :task_note
  has_one :ready_task_note
end
