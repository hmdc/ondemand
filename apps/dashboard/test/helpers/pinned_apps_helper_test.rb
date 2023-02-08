# frozen_string_literal: true

require 'test_helper'

class PinnedAppsHelperTest < ActionView::TestCase
  include PinnedAppsHelper

  def setup
    @user_configuration = stub
  end

  test 'add_query_parameters should not break with nil values' do
    assert_nil add_query_parameters(nil, nil)
  end

  test 'add_query_parameters should same URL when query parameters is empty' do
    result = add_query_parameters('/test/url', { })
    assert_equal '/test/url', result
  end

  test 'add_query_parameters should not break with empty URL when adding extra query parameters' do
    assert_equal '?param1=value1&param2=value2', add_query_parameters(nil, { param1: 'value1', param2: 'value2' })
  end

  test 'add_query_parameters should add query parameters to existing ones' do
    result = add_query_parameters('/test?static=one&test=two&', { param1: 'value1', param2: 'value2' })
    assert_equal '/test?param1=value1&param2=value2&static=one&test=two', result
  end

  test 'redirect_to_referer? should return false when pinned_apps_redirect is false' do
    @user_configuration.stubs(:pinned_apps_redirect).returns(false)
    link = OodAppLink.new({ data: {method: 'post'} })

    assert_equal false, redirect_to_referer?(link)
  end

  test 'redirect_to_referer? should return false when pinned_apps_redirect is true and OodAppLink.data does not include post method' do
    @user_configuration.stubs(:pinned_apps_redirect).returns(true)
    link = OodAppLink.new

    assert_equal false, redirect_to_referer?(link)
  end

  test 'redirect_to_referer? should return true when pinned_apps_redirect is true and OodAppLink.data includes post method' do
    @user_configuration.stubs(:pinned_apps_redirect).returns(true)
    link = OodAppLink.new({ data: {method: 'PoSt'} })

    assert_equal true, redirect_to_referer?(link)
  end
end
