# Helper for pinned apps widget
module PinnedAppsHelper

  # utility to add query string parameters to an existing URL
  def add_query_parameters(url, parameters)
    return url if parameters.to_h.empty?

    as_uri = Addressable::URI.parse(url.to_s)
    query_params = as_uri.query_values || {}
    as_uri.query_values = query_params.merge(parameters.to_h)
    as_uri.to_s
  end

  def redirect_to_referer?(link)
    @user_configuration.pinned_apps_redirect && link.data.fetch(:method, '').downcase == 'post'
  end

end