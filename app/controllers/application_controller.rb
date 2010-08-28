# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  protect_from_forgery
  layout 'application'

  before_filter :authenticate_user!
  before_filter :configuration_check
  before_filter :bson_ids
  before_filter :fix_array_params
  before_filter "hook(:app_before_filter, self)"
  after_filter  "hook(:app_after_filter, self)"
  after_filter  :log_viewed_item, :only => :show

protected
  def bson_ids
    params.each do |key, value|
      if key.to_s.match(/_id$/) || key.to_s.match(/^id$/) and BSON::ObjectID.legal?(value.to_s)
        params[key] = BSON::ObjectID.from_string(value.to_s)
      end
    end
  end

  def fix_array_params
    [:lead, :contact, :account].each do |type|
      if params[type] && params[type][:permitted_user_ids]
        params[type][:permitted_user_ids] = params[type][:permitted_user_ids].to_a
      end
    end
  end

  def render_optional_error_file(status_code)
    status = interpret_status(status_code)
    render :template => "/errors/#{status[0,3]}.html.haml", :status => status, :layout => 'errors.html.haml'
  end

  def local_request?
    false
  end

  def log_viewed_item
    subject = instance_variable_get("@#{controller_name.singularize}")
    if subject and current_user and not subject.is_a?(Search)
      Activity.log(current_user, subject, 'Viewed')
    end
  end

  def return_to_or_default( default )
    if params[:return_to] and not params[:return_to].blank?
      redirect_to params[:return_to]
    else
      redirect_to default
    end
  end

  def configuration_check
    unless @configuration ||= Configuration.first
      @configuration = Configuration.create!
    end
  end

  def freelancer_redirect
    if current_user.is_a?(Freelancer)
      redirect_to root_path
      return false
    end
  end
end
