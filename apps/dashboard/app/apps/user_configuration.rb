class UserConfiguration

  USER_PROPERTIES = [
    ConfigurationProperty.property(name: :dashboard_header_img_logo, read_from_env: true),
    # Whether we display the Dashboard logo image
    ConfigurationProperty.with_boolean_mapper(name: :disable_dashboard_logo, default_value: false, read_from_env: true),
    # URL to the Dashboard logo image
    ConfigurationProperty.property(name: :dashboard_logo, read_from_env: true),
    # Dashboard logo height used to set the height style attribute
    ConfigurationProperty.property(name: :dashboard_logo_height, read_from_env: true),

    # The dashboard's landing page layout. Defaults to nil.
    ConfigurationProperty.property(name: :dashboard_layout),
    # The configured pinned apps
    ConfigurationProperty.property(name: :pinned_apps, default_value: []),
    # The length of the "Pinned Apps" navbar menu
    ConfigurationProperty.property(name: :pinned_apps_menu_length, default_value: 6),

    ConfigurationProperty.property(name: :profile_links, default_value: []),

    ConfigurationProperty.property(name: :dashboard_title, default_value: 'Open OnDemand', read_from_env: true),
  ].freeze

  def initialize
    @config = ::Configuration.config
  end

  def dashboard_header_img_logo
    ENV['OOD_DASHBOARD_HEADER_IMG_LOGO'] || fetch(:dashboard_header_img_logo)
  end

  def disable_dashboard_logo
    ConfigurationProperty::BooleanMapper.map_string(ENV['OOD_DISABLE_DASHBOARD_LOGO']) || fetch(:disable_dashboard_logo, false)
  end

  def dashboard_logo
    ENV['OOD_DASHBOARD_LOGO'] || fetch(:dashboard_logo)
  end

  def dashboard_logo_height
    ENV['OOD_DASHBOARD_LOGO_HEIGHT'] || fetch(:dashboard_logo_height)
  end

  def dashboard_layout
    fetch(:dashboard_layout)
  end

  def pinned_apps
    fetch(:pinned_apps, [])
  end

  def pinned_apps_menu_length
    fetch(:pinned_apps_menu_length, 6)
  end

  def profile_links
    fetch(:profile_links, [])
  end

  def brand_bg_color
    color = ENV.values_at('OOD_BRAND_BG_COLOR', 'BOOTSTRAP_NAVBAR_DEFAULT_BG', 'BOOTSTRAP_NAVBAR_INVERSE_BG').compact.first
    color || fetch(:brand_bg_color)
  end

  def brand_link_active_bg_color
    color = ENV.values_at('OOD_BRAND_LINK_ACTIVE_BG_COLOR', 'BOOTSTRAP_NAVBAR_DEFAULT_LINK_ACTIVE_BG','BOOTSTRAP_NAVBAR_INVERSE_LINK_ACTIVE_BG' ).compact.first
    color || fetch(:brand_link_active_bg_color)
  end

  # Sets the Bootstrap 4 navbar type
  # See more about Bootstrap color schemes: https://getbootstrap.com/docs/4.6/components/navbar/#color-schemes
  # Supported values: ['dark', 'inverse', 'light', 'default']
  # @return [String, 'dark'] Default to dark
  def navbar_type
    type = ENV['OOD_NAVBAR_TYPE'] || fetch(:navbar_type)
    if type == 'inverse' || type == 'dark'
      'dark'
    elsif type == 'default' || type == 'light'
      'light'
    else
      'dark'
    end
  end

  # What to group pinned apps by
  # @return [String, ""] Defaults to ""
  def pinned_apps_group_by
    group_by = ENV['OOD_PINNED_APPS_GROUP_BY'] || fetch(:pinned_apps_group_by, '')

    # FIXME: the user_configuration shouldn't really know the API of
    # OodApp or subclasses. This is a hack because subclasses of OodApp overload
    # the category and subcategory to something new while saving the original.
    # The fix would be to move this knowledge to somewhere more appropriate than here.
    if group_by == 'category' || group_by == 'subcategory'
      "original_#{group_by}"
    else
      group_by
    end
  end

  def dashboard_title
    ENV['OOD_DASHBOARD_TITLE'] || fetch(:dashboard_title, 'Open OnDemand')
  end

  def public_url
    path = ENV['OOD_PUBLIC_URL'] || fetch(:public_url, '/public')
    Pathname.new path
  end

  def profile
    CurrentUser.user_settings[:profile].to_sym if CurrentUser.user_settings[:profile]
  end

  private

  def fetch(key_value, default_value = nil)
    key = key_value ? key_value.to_sym : nil
    profile_config = @config.dig(:profiles, profile) || {}

    # Returns the value if they key is present in the profile, even if the value is nil
    # This is to mimic the Hash.fetch behaviour that only uses the default_value when key is not present
    profile_config.key?(key) ? profile_config[key] : @config.fetch(key, default_value)
  end

  def add_property_methods
    UserConfiguration::USER_PROPERTIES.each do |property|
      define_singleton_method(property.name) do
        environment_value = property.map_string(ENV[property.environment_name]) if property.read_from_environment?
        environment_value.nil? ? fetch(property.name, property.default_value) : environment_value
      end
    end.each do |property|
      define_singleton_method("#{property.name}?".to_sym) do
        !send(property.name).nil?
      end
    end
  end
end