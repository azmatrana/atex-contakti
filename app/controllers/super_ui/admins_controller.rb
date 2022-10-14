class SuperUi::AdminsController < SuperadminApplicationController
  inherit_resources
  defaults resource_class: SuperAdmin, collection_name: 'admins', instance_name: 'admin', route_instance_name: 'admin', route_collection_name: 'admins', route_prefix: 'super_ui'
  actions :all, except: [:show]

  def permitted_params
    params.permit(:super_admin => [:email, :username, :password, :password_confirmation, :role_ids])
  end

  def collection
    @admins ||= end_of_association_chain.where('id <> ?', current_super_admin).decorate
  end

  def update
    @admin = ::SuperAdmin.find(params[:id])
    method = if permitted_params[:super_admin][:password].present?
               :update_with_password
             else
               :update_without_password
             end
    if @admin.__send__(method, permitted_params[:super_admin])
      redirect_to collection_url and return
    else
      render :edit
    end
  end


  def delete_service_tasks
    service_channel = ServiceChannel.find_by(id: params[:id])
    tasks = service_channel.tasks
    tasks.destroy_all

    service_channel.chat_records.destroy_all
    service_channel.chatbot_stats.destroy_all
    service_channel.orders.destroy_all

    redirect_to :back
  end

end
