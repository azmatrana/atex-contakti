module DashboardLayoutsHelper
  def layout_select_options(layouts)
    default_layout = ::DashboardLayout.default_for(current_user.company, :dashboard)
    options_for_select(@layouts.collect{ |u| [u.name, u.id] })
  end

  def localize_labels(data)
    [data[:service_channel_data], data[:location_data]].each do |c|
      c.each do |i|
        i[:label] = t("user_dashboard."+i[:label].downcase)
      end
    end
  end
end
