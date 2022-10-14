class SuperAdminRole < ActiveRecord::Base
  has_and_belongs_to_many :super_admins, join_table: :super_admins_super_admin_roles
  belongs_to :resource, polymorphic: true

  scopify
end
