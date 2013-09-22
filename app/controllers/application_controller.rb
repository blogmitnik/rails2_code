# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  layout 'application'
  helper :all # include all helpers, all the time
  include LoginSystem
  include ApplicationHelper
  include SimpleCaptcha::ControllerHelpers
  include PreferencesHelper
  before_filter :login_from_cookie, :create_page_view
  # Support for SSL. See the note in config/initializers/omniauth.rb
  # before_filter :ssl_requirement
  filter_parameter_logging :password, :password_confirmation
  
  rescue_from  Facebooker::Session::SessionExpired do
    clear_facebook_session_information
    clear_fb_cookies!
    reset_session
    redirect_to index_url
  end

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery :secret => 'f72bf9a14fd58ed0a4ebc84380fffa62c9f766004e287b2e7f8c705bc30be7c126caea95aa576333268373ca8191babcd685f246dfacc69f75416db69c9b1e0d', :digest => 'MD5'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_railscode_session'
  
  helper_method :foursquare_user, :foursquare, :foursquare_user?, :linkedin_user_session, :linkedin_user, :twitter_user?, :fbgraph_user, :last_active
  
  def last_active
    session[:last_active] ||= Time.now
  end
  
  def foursquare_user
    return nil if session[:fsq_session].blank?
    begin
      foursquare = Foursquare::Base.new(session[:fsq_session])
      @foursquare_user ||= foursquare.users.find("self")
    rescue Foursquare::InvalidAuth
      nil
    end
  end
  
  def foursquare
    unless foursquare_user?
      @foursquare ||= Foursquare::Base.new(FSQ_CLIENT_ID, FSQ_CLIENT_SECRET)
    else
      @foursquare ||= Foursquare::Base.new(session[:fsq_session])
    end
  end
  
  def foursquare_user?
    return true if is_logged_in? && session[:fsq_session]
  end
  
  def linkedin_user_session
    return @linkedin_user_session if defined?(@linkedin_user_session)
    @linkedin_user_session = UserSession.find
  end
  
  def linkedin_user
    return @linkedin_user if defined?(@linkedin_user)
    @linkedin_user = linkedin_user_session && linkedin_user_session.record
  end
  
  # Define if an user is logged in from facebook
  def twitter_user?
    return true if is_logged_in? && (session[:request_token] && session[:request_token_secret] && session[:twitter_id])
  end
  
  def fbgraph_session
    session[:fbgraph_session] 
  end
  
  def fbgraph_user
    (session[:fbgraph_session] && session[:fbgraph_uid]) ? FBGraph::Client.new(:client_id => GRAPH_APP_ID, :secret_id => GRAPH_SECRET, :token => session[:fbgraph_session]).selection.me.info! : nil
  end
  
  def facebook_session
    session[:facebook_session]
  end
  
  # Define if an user is logged in from facebook
  def facebook_user
    (session[:facebook_session] && session[:facebook_session].session_key) ? session[:facebook_session].user : nil
  end

  def load_oauth_user
    if is_logged_in? && logged_in_user.is_youtube_user?
      @access_token ||= OAuth::AccessToken.new(get_consumer, logged_in_user.oauth_token, logged_in_user.oauth_secret)
    elsif session[:oauth_token] && session[:oauth_secret]
      @access_token ||= OAuth::AccessToken.new(get_consumer, session[:oauth_token], session[:oauth_secret])
    end
  end
  
  def get_consumer
    consumer ||= begin
      options = {
          :site => "https://www.google.com",
          :request_token_path => "/accounts/OAuthGetRequestToken",
          :access_token_path => "/accounts/OAuthGetAccessToken",
          :authorize_path=> "/accounts/OAuthAuthorizeToken"
        }
      OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, options)
    end
  end
  
  def paginate(arg, options = {})
    if arg.instance_of?(Symbol) or arg.instance_of?(String)
      # Use default paginate function.
      collection_id = arg  # arg is, e.g., :specs or "specs"
      super(collection_id, options)
    else
      items = arg  # arg is a list of items, e.g., users
      items_per_page = options[:per_page] || 5
      page = (params[:page] || 1).to_i
      result_pages = Paginator.new(self, items.length, items_per_page, page)
      offset = (page - 1) * items_per_page
      [result_pages, items[offset..(offset + items_per_page - 1)]]
    end
  end
  
  # Insert KISSmetrics if we are in production
  def ssl_requirement
    return unless Rails.env.production?
    if ssl_required? && ! request.ssl? then
      # Send to https://
      flash.keep
      redirect_to 'https://' + request.host_with_port + request.fullpath
    elsif ! ssl_required? && request.ssl? then
      # Send to http://
      flash.keep
      redirect_to 'http://' + request.host_with_port + request.fullpath
    end
  end
  
  # Does this action require SSL?
  def ssl_required?
    ! Rails.env.test?
  end
  
  helper_method :flickr, :flickr_images
  
  # API objects that get built once per request
  def flickr(user_name = nil, tags = nil )
    @flickr_object ||= Flickr.new(FLICKR_CACHE, FLICKR_KEY, FLICKR_SECRET)
  end
  
  def flickr_images(user_name = "", tags = "")
    unless RAILS_ENV == "test"# || RAILS_ENV == "development"
      begin
        flickr.photos.search(user_name.blank? ? nil : user_name, tags.blank? ? nil : tags , nil, nil, nil, nil, nil, nil, nil, nil, 8)
      rescue
        nil
      rescue Timeout::Error
        nil
      end
    end
  end
  
  
  private
  
  
  def admin_required
    unless admin?
      redirect_to index_url
    end
  end
  
  def create_page_view
    PageView.create(:user_id => session[:user_id],
                    :request_url => request.request_uri,
                    :ip_address => request.remote_ip,
                    :referer => request.env["HTTP_REFERER"],
                    :user_agent => request.env["HTTP_USER_AGENT"])
    if is_logged_in?
      # last_login_at actually captures site activity, so update it now.
      logged_in_user.last_login_at = Time.now
      logged_in_user.save
    end
  end

end
