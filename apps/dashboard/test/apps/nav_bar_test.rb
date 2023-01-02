require 'test_helper'

class NavBarTest < ActiveSupport::TestCase

  def setup
    # Mock the sys installed applications
    OodAppkit.stubs(:clusters).returns(OodCore::Clusters.load_file('test/fixtures/config/clusters.d'))
    SysRouter.stubs(:base_path).returns(Rails.root.join("test/fixtures/sys_with_gateway_apps"))
  end

  test "NavBar.items should return navigation template when nav_item is a string matching a static template" do
    nav_item = "all_apps"

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/all_apps",  result[0].partial_path
    assert_equal [], result[0].apps
  end

  test "NavBar.items should return navigation link with URL overridden when nav_item has url property and it matches an static link" do
    nav_item = {
      title: "link title",
      url: "sessions"
    }

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/link",  result[0].partial_path
    assert_equal "link title",  result[0].title
    assert_equal "/batch_connect/sessions",  result[0].url
  end

  test "NavBar.items should return navigation link when nav_item is a string matching one app token" do
    nav_item = "sys/bc_jupyter"

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/link",  result[0].partial_path
    assert_equal 1,  result[0].links.size
    assert_equal '',  result[0].links[0].category
    assert_equal '',  result[0].links[0].subcategory
    assert_equal "Jupyter Notebook",  result[0].title
    assert_equal "/batch_connect/sys/bc_jupyter/session_contexts/new",  result[0].url
  end

  test "NavBar.items should ignore nav_items when is a string and matching app has no links" do
    mock_app = stub()
    mock_app.stubs(:has_sub_apps?).returns(false)
    mock_app.stubs(:token).returns("test/token")
    mock_app.stubs(:links).returns([])
    Router.stubs(:pinned_apps_from_token).returns([mock_app])

    assert_equal [],  NavBar.items(["test/token"])
  end

  test "NavBar.items should ignore nav_items when is a string and does not match any sys applications" do
    assert_equal [],  NavBar.items(["sys/not_found"])
  end

  test "NavBar.items should ignore nav_item when nav_item is a string matching multiple app tokens" do
    nav_item = "sys/bc_*"

    result = NavBar.items([nav_item])
    assert_equal [],  result
  end

  test "NavBar.items should return navigation group when nav_item is a string matching a sys application category" do
    nav_item = "Interactive Apps"

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/group",  result[0].partial_path
    assert_equal "Interactive Apps",  result[0].title
    assert_equal 4,  result[0].apps.size
  end

  test "nav_item string category matching should be case insensitive" do
    nav_item = "intEractivE APPs"

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/group",  result[0].partial_path
    assert_equal "Interactive Apps",  result[0].title
    assert_equal 4,  result[0].apps.size
  end

  test "NavBar.items should return navigation group when nav_item has apps and title property" do
    nav_item = {
      title: "Custom Apps",
      icon_uri: "fa://test",
      apps: "sys/bc_jupyter"
    }

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/group",  result[0].partial_path
    assert_equal 1,  result[0].links.size
    assert_equal 'Custom Apps',  result[0].links[0].category
    assert_equal 'Apps',  result[0].links[0].subcategory
    assert_equal 'Custom Apps',  result[0].title
    assert_equal URI("fa://test"),  result[0].icon_uri
  end

  test "icon_uri should be null for apps navigation group when nav_item has no icon_uri property" do
    nav_item = {
      title: "Custom Apps",
      apps: "sys/bc_jupyter"
    }

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/group",  result[0].partial_path
    assert_equal "Custom Apps",  result[0].title
    assert_nil result[0].icon_uri
  end

  test "NavBar.items should return navigation group when nav_item has apps array and title property" do
    nav_item = {
      title: "Custom Apps",
      icon_uri: "fa://test",
      apps: ["sys/bc_jupyter"]
    }

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/group",  result[0].partial_path
    assert_equal 1,  result[0].links.size
    assert_equal 'Custom Apps',  result[0].links[0].category
    assert_equal 'Apps',  result[0].links[0].subcategory
    assert_equal 'Custom Apps',  result[0].title
    assert_equal URI("fa://test"),  result[0].icon_uri
  end

  test "NavBar.items should return navigation group when nav_item has links property" do
    nav_item = {
      title: "menu title",
      icon_uri: "fa://test",
      links: []
    }

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/group",  result[0].partial_path
    assert_equal 0,  result[0].apps.size
    assert_equal "menu title",  result[0].title
    assert_equal URI("fa://test"),  result[0].icon_uri
  end

  test "icon_uri should be null for links navigation group when nav_item has no icon_uri property" do
    nav_item = {
      title: "menu title",
      links: []
    }

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/group",  result[0].partial_path
    assert_equal "menu title",  result[0].title
    assert_nil result[0].icon_uri
  end

  test "NavBar.items should set subcategory to groups inside links when nav_item only known property is group" do
    nav_item = {
      title: "menu title",
      links: [
        {group: "subcategory1"},
        "sys/bc_jupyter",
        {group: "subcategory2"},
        "sys/bc_jupyter"
      ]
    }

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/group",  result[0].partial_path
    assert_equal "menu title",  result[0].title
    assert_equal 2,  result[0].apps.size
    assert_equal "menu title",  result[0].apps[0].category
    assert_equal "subcategory1",  result[0].apps[0].subcategory
    assert_equal "menu title",  result[0].apps[1].category
    assert_equal "subcategory2",  result[0].apps[1].subcategory
  end

  test "NavBar.items should return navigation link when nav_item has url property" do
    nav_item = {
      title: "Link Title",
      url: "/path/test",
      new_tab: true
    }

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/link",  result[0].partial_path
    assert_equal 1, result[0].links.size
    assert_equal "Link Title",  result[0].title
    assert_equal "/path/test",  result[0].url
    assert_equal true,  result[0].new_tab?
  end

  test "navigation link new_tab? defaults to false" do
    nav_item = {
      title: "Link Title",
      url: "/path/test",
    }

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/link",  result[0].partial_path
    assert_equal 1, result[0].links.size
    assert_equal false,  result[0].new_tab?
  end

  test "NavBar.items should return navigation profile when nav_item has profile property" do
    nav_item = {
      title: "Profile Title",
      profile: "profile1",
      new_tab: true
    }
    expected_data_property = { method: 'post' }
    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/link",  result[0].partial_path
    assert_equal 1, result[0].links.size
    assert_equal "Profile Title",  result[0].title
    assert_equal "/settings?settings%5Bprofile%5D=profile1",  result[0].url
    assert_equal expected_data_property,  result[0].data
    assert_equal true,  result[0].new_tab?
  end

  test "navigation profile new_tab? defaults to false" do
    nav_item = {
      title: "Profile Title",
      profile: "profile1",
    }

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/link",  result[0].partial_path
    assert_equal 1, result[0].links.size
    assert_equal false,  result[0].new_tab?
  end

  test "NavBar.items should return navigation page when nav_item has page property" do
    nav_item = {
      title: "Page Title",
      page: "page_code",
      new_tab: true,
    }
    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/link",  result[0].partial_path
    assert_equal 1, result[0].links.size
    assert_equal "Page Title",  result[0].title
    assert_equal "/custom/page_code",  result[0].url
    assert_equal true,  result[0].new_tab?
  end

  test "navigation page new_tab? defaults to false" do
    nav_item = {
      title: "Page Title",
      page: "page_code",
    }

    result = NavBar.items([nav_item])
    assert_equal 1,  result.size
    assert_equal "layouts/nav/link",  result[0].partial_path
    assert_equal 1, result[0].links.size
    assert_equal false,  result[0].new_tab?
  end

  test "NavBar should keep navigation order from configuration" do
    titles = (1..10).to_a.map{ |_| SecureRandom.uuid }
    config = titles.map{ |x| {title: x, links: []} }

    result = NavBar.items(config)
    assert_equal 10,  result.size
    titles.each_with_index do |title, index|
      assert_equal title,  result[index].title
    end
  end

  test "NavBar.items should return empty list when empty configuration provided" do
    assert_equal true,  NavBar.items([]).empty?
  end

  test "NavBar.items should discard invalid configuration items" do
    valid_item = "sys/bc_jupyter"

    result = NavBar.items([stub(), valid_item, stub()])
    assert_equal 1,  result.size
    assert_equal "Jupyter Notebook",  result[0].title
  end

  test "Check supported static templates" do
    NavBar::STATIC_TEMPLATES.each do |name, _|
      assert_equal true,  [:all_apps, :featured_apps, :sessions, :log_out, :user].include?(name)
    end
  end

  test "Check supported static links" do
    NavBar::STATIC_LINKS.each do |name, _|
      assert_equal true,  [:root, :all_apps, :featured_apps, :sessions, :jobs, :support_ticket, :products_dev, :products_usr, :restart].include?(name)
    end
  end

  test "NavBar.menu_items should return a group based NavItemDecorator" do
    nav_item = {
      title: "menu title",
      links: [
        {group: "subcategory1"},
        "sys/bc_jupyter",
        {group: "subcategory2"},
        "sys/bc_jupyter"
      ]
    }

    result = NavBar.menu_items(nav_item)
    assert_equal "layouts/nav/group",  result.partial_path
    assert_equal "menu title",  result.title
    assert_equal 2,  result.apps.size
    assert_equal "menu title",  result.apps[0].category
    assert_equal "subcategory1",  result.apps[0].subcategory
    assert_equal "menu title",  result.apps[1].category
    assert_equal "subcategory2",  result.apps[1].subcategory
  end

  test "NavBar.menu_items should return empty group when nav_item is empty hash" do
    result = NavBar.menu_items({})
    assert_equal "layouts/nav/group",  result.partial_path
    assert_equal "",  result.title
    assert_equal 0,  result.apps.size
  end

  test "NavBar.menu_items should return empty group when nav_item is nil" do
    result = NavBar.menu_items(nil)
    assert_equal "layouts/nav/group",  result.partial_path
    assert_equal "",  result.title
    assert_equal 0,  result.apps.size
  end

end