class RolifyCreateSuperAdminRoles < ActiveRecord::Migration
  def change
    create_table(:super_admin_roles) do |t|
      t.string :name
      t.references :resource, :polymorphic => true

      t.timestamps
    end

    create_table(:super_admins_super_admin_roles, :id => false) do |t|
      t.references :super_admin
      t.references :super_admin_role
    end

    add_index(:super_admin_roles, :name)
    add_index(:super_admin_roles, [ :name, :resource_type, :resource_id ], name: 'super_admin_roles_index1')
    add_index(:super_admins_super_admin_roles, [ :super_admin_id, :super_admin_role_id ], name: 'super_admin_roles_index2')
  end
end
