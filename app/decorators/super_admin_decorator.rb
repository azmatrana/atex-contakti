class SuperAdminDecorator < ApplicationDecorator
  def current_role
    if object.has_role?(:superadmin)
      'SuperAdmin'
    else
      'Admin'
    end
  end
end
