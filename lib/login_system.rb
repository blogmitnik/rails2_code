require 'json'
require 'oauth'

module LoginSystem
  class GeneralError < StandardError
  end
  class RequestError < LoginSystem::GeneralError
  end
  class NotInitializedError < LoginSystem::GeneralError
  end
  
  # controller method to handle twitter callback (expected after login_by_oauth invoked)
  def callback
    self.twitagent.exchange_request_for_access_token( session[:request_token], session[:request_token_secret], params[:oauth_verifier] )
    user_info = self.twitagent.verify_credentials
    raise LoginSystem::RequestError unless user_info['id'] && user_info['screen_name'] && user_info['profile_image_url']

    # We have an authorized user, save the information to the database.
    @user = User.find_by_screen_name(user_info['screen_name'])
    if @user == nil
      # Authenticate from user's setting page or status_update twitter button
      if is_logged_in? # If user is logged in and no Twitter ID in the database!
        logged_in_user.update_attributes(
          :twitter_id => user_info['id'],
          :screen_name => user_info['screen_name'],
          :token => self.twitagent.access_token.token,
          :secret => self.twitagent.access_token.secret,
          :profile_image_url => user_info['profile_image_url'])
        self.twitagent( user_token = logged_in_user.token, user_secret = logged_in_user.secret )
        flash[:notice] = "你的帳戶已與 Twitter 建立連接。下次您可以使用這個帳號來登入"
        return redirect_to user_path(logged_in_user)
      else
        # Authenticate from signup page
        @user = User.new({ 
          :twitter_id => user_info['id'],
          :screen_name => user_info['screen_name'],
          :token => self.twitagent.access_token.token,
          :secret => self.twitagent.access_token.secret,
          :profile_image_url => user_info['profile_image_url'] })
        flash[:notice] = "已完成 Twitter 帳戶驗證，接下來我們需要您填寫一些基本資料"
        @title = "註冊 #{app_name} 帳戶"
        render :action => 'new'
      end
    else
      if is_logged_in? && !is_me?(@user)
        flash[:error] = "抱歉，這個 Twitter 帳戶已經與其他帳戶連結了"
        redirect_back_or_default('/')
      else # Logged user in via twitter oauth
        @user.token = self.twitagent.access_token.token
        @user.secret = self.twitagent.access_token.secret
        @user.profile_image_url = user_info['profile_image_url']
        self.logged_in_user = @user
        self.logged_in_user.increment!(:signin_count)
        flash[:notice] = "嗨 #{@user.screen_name}，你已經透過 Twitter 帳戶登入"
        return redirect_back_or_default('/')
      end
    end
  end
  
protected
  
  # Inclusion hook to make #logged_in_user, #is_logged_in? available as ActionView helper methods.
  def self.included(base)
    base.send :helper_method, :logged_in_user, :is_logged_in?, :facebook_user if base.respond_to? :helper_method
  end

  def twitagent( user_token = nil, user_secret = nil )
    self.twitagent = TwitterOauth.new( user_token, user_secret )  if user_token && user_secret
    self.twitagent = TwitterOauth.new( ) unless @twitagent
    @twitagent ||= raise LoginSystem::NotInitializedError
  end
  
  def twitagent=(new_agent)
    @twitagent = new_agent || false
  end
    
  #Check username and password to ensure a login user
  def is_logged_in?
    @logged_in_user ||= (login_from_session || login_from_basic_auth || login_from_cookie || login_from_twitter) unless @logged_in_user == false
  end

  #If is_logged_in? is true, then return the @logged_in_user variable
  def logged_in_user
    return @logged_in_user if is_logged_in?
  end
  
  #Log a user in
  def logged_in_user=(user)
    if !user.nil? || user.is_a?(Symbol)
      # use for twitter oauth login user
      if user.is_twitter_user?
        request_token = self.twitagent.get_request_token
        session[:request_token] = request_token.token
        session[:request_token_secret] = request_token.secret
        session[:twitter_id] = user.twitter_id
        self.twitagent( user_token = user.token, user_secret = user.secret )
      end
      if user.is_foursquare_user?
        session[:fsq_session] = user.foursquare_token
      end
      session[:user] = user.id
      @logged_in_user = user
      session[:last_active] = @logged_in_user.last_login_at
      session[:topics] = session[:forums] = {}
      update_last_login_at
    else
      session[:request_token] = session[:request_token_secret] = session[:twitter_id] = nil 
      self.twitagent = false
      @logged_in_user = false
    end
  end
  
  def update_last_login_at
    return unless is_logged_in?
    User.update_all ['last_login_at = ?', Time.now.utc], ['id = ?', logged_in_user.id] 
    logged_in_user.last_login_at = Time.now.utc
  end

  def check_role(role)
    unless is_logged_in? && @logged_in_user.has_role?(role)
       respond_to do |wants|
         wants.html do
           flash[:error] = "你沒有足夠的權限執行這個動作"
           redirect_to index_url
       end
         wants.xml do
          headers['Status'] = 'Unauthorized'
          headers['WWW-Authenticate'] = %(Basic realm="Password")
          render :text => "Insuffient permission", :status => '401 Unauthorized', :layout => false
       end
      end
    end
  end
  
  def check_administrator_role
    check_role('Administrator')
  end
  
  def check_editor_role
    check_role('Editor')
  end
  
  def check_moderator_role
    check_role('Moderator')
  end
  
  def login_required
    unless is_logged_in?
        respond_to do |wants|
          wants.html do
            session[:protected_page] = request.request_uri
            flash[:error] = "你必須先登入，才能查看這個頁面。"
            redirect_to login_url
            return false
        end
          wants.xml do
            headers["Status"] = "Unauthorized"
            headers["WWW-Authenticate"] = %(Basic realm="Web Password")
            render :text => "無法驗證您的身份", :status => '401 Unauthorized', :layout => false
         end
      end
    end
  end
  
  # Use this filter method for Twitter related actions!
  def oauth_login_required
    return if is_logged_in? && login_from_twitter# && logged_in_user.twitter_id != nil
    login_by_oauth
  end
  
  # Store the URI of the current request in the session.
  # We can return to this location by calling #redirect_back_or_default.
  # Only store html requests so we don't redirect a user back to and rss or xml feed
  def store_location
    if request.format == :html
      session[:return_to] = request.request_uri
    end
  end

  def store_referer
    session[:refer_to] = request.env["HTTP_REFERER"]
  end
  
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
  
  def redirect_to_referer_or_default(default)
    redirect_to(session[:refer_to] || default)
    session[:refer_to] = nil
  end

  # cookie and log the user back in if apropriate
   def login_from_cookie
     return unless cookies[:auth_token]
     user = User.find_by_remember_token(cookies[:auth_token])
     if user && user.remember_token?
       user.remember_me
       self.logged_in_user = user
       cookies[:auth_token] = { :value => self.logged_in_user.remember_token , 
         :expires => self.logged_in_user.remember_token_expires_at }
     end
   end
   
   def login_from_session
     self.logged_in_user = User.find(session[:user]) if session[:user]
   end
   
   def login_from_twitter
     self.logged_in_user = User.find_by_twitter_id(session[:twitter_id]) if session[:twitter_id]
   end
  
   def login_by_oauth
     request_token = self.twitagent.get_request_token
     session[:request_token] = request_token.token
     session[:request_token_secret] = request_token.secret
     # Send to twitter.com to authorize
     redirect_to request_token.authorize_url
   rescue
     # The user might have rejected this application. Or there was some other error during the request.
     RAILS_DEFAULT_LOGGER.error "Failed to login via OAuth"
     flash[:error] = "存取 Twitter API 時發生錯誤"
     redirect_to index_url
   end
   
   def login_from_basic_auth
     email, password = get_http_auth_data
     authenticate_with_http_basic do |email, password|
       self.logged_in_user = User.authenticate(email, password)
     end
   end
   
   def logout_keeping_session!
     @logged_in_user.forget_me if @logged_in_user.is_a? User
     @logged_in_user = false   # not logged in, and don't do it for me
     kill_remember_cookie!     # Kill client-side auth cookie
     session[:user_id] = nil
     session[:facebook_session] = nil
     session[:fbgraph_session] = session[:fbgraph_uid] = nil
     session[:fsq_session] = nil
     session[:request_token] = session[:request_token_secret] = session[:twitter_id] = nil
     linkedin_user_session.destroy if linkedin_user
   end
   
   def logout_killing_session!
     logout_keeping_session!
     reset_session
   end
   
   def valid_remember_cookie?
     return nil unless @logged_in_user
     (@logged_in_user.remember_token?) && (cookies[:auth_token] == @logged_in_user.remember_token)
   end
   
   # Refresh the cookie auth token if it exists, create it otherwise
    def handle_remember_cookie! new_cookie_flag
      return unless @logged_in_user
      case
        when valid_remember_cookie? then @logged_in_user.refresh_token
        when new_cookie_flag        then @logged_in_user.remember_me 
        else                             @logged_in_user.forget_me
      end
      send_remember_cookie!
    end
  
    def kill_remember_cookie!
      cookies.delete :auth_token
    end
    
    def send_remember_cookie!
      cookies[:auth_token] = {
        :value   => @logged_in_user.remember_token,
        :expires => @logged_in_user.remember_token_expires_at }
    end
    
  # controller wrappers for twitter API methods

  # Twitter REST API Method: statuses/update
  def update_twitter_status!(  status , in_reply_to_status_id = nil )
    self.twitagent.update_twitter_status!(  status , in_reply_to_status_id )
  rescue => err
    # The user might have rejected this application. Or there was some other error during the request.
    RAILS_DEFAULT_LOGGER.error "#{err.message} Failed update twitter status"
    return
  end

  # Twitter REST API Method: statuses friends
  def friends(user=nil)
    self.twitagent.friends(user)
  rescue => err
    RAILS_DEFAULT_LOGGER.error "Failed to get friends via OAuth for #{logged_in_user.inspect}"
    flash[:error] = "Twitter API發生錯誤 (getting friends)"
    return
  end

  # Twitter REST API Method: statuses followers
  def followers(user=nil)
    self.twitagent.followers(user)
  rescue => err
    RAILS_DEFAULT_LOGGER.error "Failed to get followers via OAuth for #{logged_in_user.inspect}"
    flash[:error] = "Twitter API發生錯誤 (getting followers)"
    return
  end

  # Twitter REST API Method: statuses mentions
  def mentions( since_id = nil, max_id = nil , count = nil, page = nil )
    self.twitagent.mentions( since_id, max_id, count, page )
  rescue => err
    RAILS_DEFAULT_LOGGER.error "Failed to get mentions via OAuth for #{logged_in_user.inspect}"
    flash[:error] = "Twitter API發生錯誤 (getting mentions)"
    return
  end

  # Twitter REST API Method: direct_messages
  def direct_messages( since_id = nil, max_id = nil , count = nil, page = nil )
    self.twitagent.direct_messages( since_id, max_id, count, page )
  rescue => err
    RAILS_DEFAULT_LOGGER.error "Failed to get direct_messages via OAuth for #{logged_in_user.inspect}"
    flash[:error] = "Twitter API發生錯誤 (getting direct_messages)"
    return
  end
  
  
  private
  
    def redirect_to_forwarding_url
      if (redirect_url = session[:protected_page])
        session[:protected_page] = nil
        redirect_to redirect_url
      else
        redirect_to index_url
      end
    end
    
    def get_http_auth_data
      email, password = nil, nil
      auth_headers = ['X-HTTP_AUTHORIZATION', 'Authorization', 'HTTP_AUTHORIZATION', 
        'REDIRECT_REDIRECT_X_http_AUTHORIZATION']
      auth_header = auth_headers.detect { |key| request.env[key] }
      auth_data = request.env[auth_header].to_s.split
  
      if auth_data && auth_data[0] == 'Basic'
        email, password = Base64.decode64(auth_data[1]).split(':')[0..1] 
      end 
      return [email, password]
    end
  
end