# Creates navigation items based on user configuration.
#
class NavBar

  STATIC_LINKS = {
    root: Rails.application.routes.url_helpers.root_path,
    all_apps: Rails.application.routes.url_helpers.apps_index_path,
    featured_apps: Rails.application.routes.url_helpers.apps_index_path,
    sessions: Rails.application.routes.url_helpers.batch_connect_sessions_path,
    jobs: Rails.application.routes.url_helpers.respond_to?(:activejobs_path) ? Rails.application.routes.url_helpers.activejobs_path : nil,
    support_ticket: Rails.application.routes.url_helpers.respond_to?(:support_path) ? Rails.application.routes.url_helpers.support_path : nil,
    products_dev:  Rails.application.routes.url_helpers.products_path(type: "dev"),
    products_usr: Rails.application.routes.url_helpers.products_path(type: "usr"),
    restart: "/nginx/stop?redir=#{Rails.application.routes.url_helpers.root_path}",
  }.freeze

  STATIC_TEMPLATES = {
    all_apps: "layouts/nav/all_apps",
    featured_apps: "layouts/nav/featured_apps",
    sessions: "layouts/nav/sessions",
    log_out: "layouts/nav/log_out",
    user: "layouts/nav/user",
  }.freeze

  def self.items(nav_config)
    nav_config.map do |nav_item|
      if nav_item.is_a?(String)
        item_from_token(nav_item)
      elsif nav_item.is_a?(Hash)
        if nav_item[:links]
          extend_group(nav_menu(nav_item))
        elsif nav_item[:url]
          extend_link(nav_link(nav_item))
        elsif nav_item[:apps] && nav_item[:title]
          matched_apps = nav_apps(nav_item, nav_item[:title], nil)
          extend_group(OodAppGroup.new(apps: matched_apps, title: nav_item[:title], icon_uri: nav_item[:icon_uri], sort: true))
        elsif nav_item[:profile]
          extend_link(nav_profile(nav_item))
        elsif nav_item[:page]
          extend_link(nav_page(nav_item))
        end
      end
    end.flatten.compact
  end

  def self.menu_items(menu_item)
    extend_group(nav_menu(menu_item || {}))
  end

  private

  def self.nav_menu(hash_item)
    menu_title = hash_item.fetch(:title, '')
    menu_icon = hash_item.fetch(:icon_uri, nil)
    menu_items = hash_item.fetch(:links, [])

    group_title = ''
    apps = menu_items.map do |item|
      if item.is_a?(String)
        item = { apps: item }
      end

      if item[:url]
        nav_link(item, menu_title, group_title)
      elsif item[:apps]
        nav_apps(item, menu_title, group_title)
      elsif item[:profile]
        nav_profile(item, menu_title, group_title)
      elsif item[:page]
        nav_page(item, menu_title, group_title)
      else
        # Update subcategory if group title was provided
        group_title = item.fetch(:group, group_title)
        next nil
      end
    end.flatten.compact

    OodAppGroup.new(apps: apps, title: menu_title, icon_uri: menu_icon, sort: false)
  end

  def self.nav_link(item, category='', subcategory='')
    link_data = item.clone
    # Override URL with static link if there is match
    static_url = STATIC_LINKS[item.fetch(:url).to_sym]
    link_data[:url] = static_url if static_url
    link_data[:new_tab] = item.fetch(:new_tab, false)
    OodAppLink.new(link_data).categorize(category: category, subcategory: subcategory)
  end

  def self.nav_apps(item, category='', subcategory='')
    app_configs = Array.wrap(item.fetch(:apps, []))
    app_configs.map do |config_string|
      matched_apps = Router.pinned_apps_from_token(config_string, SysRouter.apps)
      extract_links(matched_apps, category: category, subcategory: subcategory)
    end.flatten
  end

  def self.nav_profile(item, category='', subcategory='')
    profile = item.fetch(:profile)
    profile_data = item.clone
    profile_data[:title] = item.fetch(:title, profile.titleize)
    profile_data[:url] = Rails.application.routes.url_helpers.settings_path('settings[profile]' => profile)
    profile_data[:data] = { method: 'post' }
    profile_data[:new_tab] = item.fetch(:new_tab, false)
    OodAppLink.new(profile_data).categorize(category: category, subcategory: subcategory)
  end

  def self.nav_page(item, category='', subcategory='')
    page_code = item.fetch(:page)
    page_data = item.clone
    page_data[:title] = page_data.fetch(:title, page_code.titleize)
    page_data[:url] = Rails.application.routes.url_helpers.custom_pages_path(page_code)
    page_data[:new_tab] = page_data.fetch(:new_tab, false)
    OodAppLink.new(page_data).categorize(category: category, subcategory: subcategory)
  end

  def self.item_from_token(token)
    static_template = STATIC_TEMPLATES.fetch(token.to_sym, nil)
    if static_template
      return NavItemDecorator.new(OodAppGroup.new, static_template)
    end

    matched_apps = Router.pinned_apps_from_token(token, SysRouter.apps)
    if matched_apps.size == 1
      app = AppRecategorizer.new(matched_apps.first, category: '', subcategory: '')
      extend_link(app.links.first.categorize(show_in_menu: app.batch_connect_app?)) if app.links.first
    else
      group = OodAppGroup.groups_for(apps: SysRouter.apps).select { |g| g.title.downcase == token.downcase }.first
      return nil if group.nil?
      group.apps = extract_links(group.apps)
      extend_group(group)
    end
  end

  def self.extract_links(apps, category: nil, subcategory: nil)
    apps.map do |app|
      app.links.map do |link|
        link.categorize(category: category || app.category, subcategory: subcategory || app.subcategory, show_in_menu: app.batch_connect_app?)
      end
    end.flatten
  end

  def self.extend_group(group)
    group.sort = false
    NavItemDecorator.new(group, 'layouts/nav/group')
  end

  def self.extend_link(link)
    NavItemDecorator.new(link, 'layouts/nav/link')
  end

  class NavItemDecorator < SimpleDelegator
    attr_reader :partial_path, :links

    def initialize(nav_item, partial_path)
      super(nav_item)
      @partial_path = partial_path
      @links = nav_item.links.flatten.compact
    end
  end
end