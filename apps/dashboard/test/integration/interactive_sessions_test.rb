require 'html_helper'
require 'test_helper'

class InteractiveSessionsTest < ActionDispatch::IntegrationTest

  def setup
    value = '{"id":"1234","job_id":"1","created_at":1669139262,"token":"sys/token","title":"session title","cache_completed":false}'
    session = BatchConnect::Session.new.from_json(value)
    session.stubs(:status).returns(OodCore::Job::Status.new(state: :running))
    BatchConnect::Session.stubs(:all).returns([session])
  end

  test 'should render session panel with delete button when terminate_session_enabled is false (default)' do
    Configuration.stubs(:terminate_session_enabled).returns(false)

    get batch_connect_sessions_path
    assert_response :success

    puts css_select 'body'
    puts css_select 'div#id_1234'
    puts css_select 'div#id_1234 div.card-body'

    assert_select 'div#id_1234 div.card-body div.float-right a' do |link|
      assert_equal I18n.t('dashboard.batch_connect_sessions_delete_title'), link.first.text.strip
      assert_equal batch_connect_session_path('1234'), link.first['href']
    end
  end

  test 'should render session panel with terminate button when terminate_session_enabled is true' do
    Configuration.stubs(:terminate_session_enabled).returns(true)

    get batch_connect_sessions_path
    assert_response :success

    assert_select 'div#id_1234 div.card-body div.float-right a' do |link|
      assert_equal I18n.t('dashboard.batch_connect_sessions_terminate_title'), link.first.text.strip
      assert_equal batch_connect_session_path('1234', delete: false), link.first['href']
    end
  end
end
