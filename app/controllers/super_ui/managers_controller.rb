class SuperUi::ManagersController < SuperadminApplicationController
  inherit_resources
  defaults resource_class: User

  def permitted_params
    params.permit!
  end

  def create
    create! do
      if @manager.valid?
        @manager.add_role :admin
        super_ui_manager_path(@manager)
      else
        new_super_ui_manager_path
      end
    end
  end

  protected
    def collection
      @managers = ::User.with_role :admin
    end
end
