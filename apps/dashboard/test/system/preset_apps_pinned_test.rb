# frozen_string_literal: true

require 'application_system_test_case'

# Very similar to preset_apps_navbar_test.rb only in that there are
# Pinned apps that _have_ to be stubbed in setup. If these files were combined,
# you wouldn't be able to tell what's the navbar entry and which is the pinned app
class PresetAppsPinnedTest < ApplicationSystemTestCase

  def setup
    OodAppkit.stubs(:clusters).returns(OodCore::Clusters.load_file('test/fixtures/config/clusters.d'))
    SysRouter.stubs(:base_path).returns(Rails.root.join('test/fixtures/apps'))

    BatchConnect::Session.stubs(:all).returns([])
    BatchConnect::Session.any_instance.stubs(:save).returns(true)

    Router.instance_variable_set('@pinned_apps', nil)
  end

  def teardown
    Router.instance_variable_set('@pinned_apps', nil)
  end

  test 'preset apps in pinned apps directly launch' do
    stub_user_configuration({ pinned_apps: ['sys/preset_app/*']})
    visit root_path
    click_on 'Test App: Preset'

    verify_bc_success(expected_path: batch_connect_sessions_path)
  end

  test 'preset apps in pinned apps should launch and redirect to referrer when pinned_apps_redirect is true' do
    stub_user_configuration({ pinned_apps_redirect: true, pinned_apps: ['sys/preset_app/*']})
    visit root_path
    click_on 'Test App: Preset'

    verify_bc_success(expected_path: root_path)
  end

  test 'choice apps in pinned apps still redirect to the form' do
    stub_user_configuration({ pinned_apps: ['sys/preset_app/*']})
    visit root_path
    click_on 'Test App: Choice'

    # we can click the launch button and it does the same thing as above.
    assert_equal new_batch_connect_session_context_path('sys/preset_app/choice'), current_path
    click_on 'Launch'

    verify_bc_success(expected_path: batch_connect_sessions_path)
  end
end
