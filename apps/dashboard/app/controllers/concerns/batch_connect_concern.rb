# Concerns for the batch connect controllers.
module BatchConnectConcern
  extend ActiveSupport::Concern

  def bc_sys_app_groups
    OodAppGroup.groups_for(
      apps: nav_sys_apps.select(&:batch_connect_app?)
    )
  end

  def bc_usr_app_groups
    apps = nav_usr_apps.select(&:batch_connect_app?)
    if apps.empty?
      []
    else
      [ OodAppGroup.new(title: t('dashboard.shared_apps_title'), apps: apps) ]
    end
  end

  def bc_dev_app_groups
    OodAppGroup.groups_for(
      apps: nav_dev_apps.select(&:batch_connect_app?)
    )
  end

  def bc_custom_apps_group
    if !@user_configuration.apps_menu.blank?
      # Apps menu override takes precedence
      NavBar.items([@user_configuration.apps_menu]).first
    elsif !@nav_bar.blank?
      # Create a custom list of batch connect applications based on the custom navigation defined
      apps = @nav_bar.map(&:apps).compact.flatten.select { |app| app.respond_to?(:batch_connect_app?) && app.batch_connect_app? }
      OodAppGroup.new(apps: apps, title: t('dashboard.batch_connect_apps_menu_title'), sort: true)
    end
    # Return nil otherwise
  end
end
