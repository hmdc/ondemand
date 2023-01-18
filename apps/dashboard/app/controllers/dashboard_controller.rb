# The controller for dashboard (root) pages /dashboard
class DashboardController < ApplicationController
  def index

    @recently_used_apps = recently_used_apps

    begin
      @motd = MotdFile.new.formatter
    rescue StandardError => e
      flash.now[:alert] = t('dashboard.motd_erb_render_error', error_message: e.message)
    end
    set_my_quotas
  end

  def logout
  end

  def recently_used_apps
    cache_files = BatchConnect::Session.cache_root.children.map{|pathname| pathname.basename.to_s}
    base_apps = SysRouter.apps.select(&:batch_connect_app?).map do |ood_app|
      ood_app.sub_app_list.select do |batch_connect_app|
        cache_files.include?(batch_connect_app.cache_file)
      end.map do |matched_batch_connect_app|
        session_context = matched_batch_connect_app.build_session_context
        cache_file = BatchConnect::Session.cache_root.join(matched_batch_connect_app.cache_file)
        matched_batch_connect_app.update_session_with_cache(session_context, cache_file)
        matched_batch_connect_app
      end
    end.flatten
    base_apps
  end
end
