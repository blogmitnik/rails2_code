class UsersController < ApplicationController
  before_filter :ssl_requirement, :only => [:new, :create, :edit, :update]
  before_filter :oauth_login_required, :only => [ :oauth, :update_twitter_status, :partialfriends, :partialfollowers, :partialmentions, :partialdms ]
  before_filter :init_member, :only => [ :oauth, :update_twitter_status, :partialfriends, :partialfollowers, :partialmentions, :partialdms ]
  before_filter :access_check, :only => [ :oauth, :update_twitter_status, :partialfriends, :partialfollowers, :partialmentions, :partialdms ]
  
  skip_filter :store_location, :only => [:new, :create, :edit, :update, :destory, :welcome, :enable, :delete_icon]
  before_filter :admin_required, :only => [:admin, :enable]
  before_filter :login_required, :only => [:show, :edit, :update, :delete_icon]
  before_filter :setup
  
  protect_from_forgery :except => :liveAuth 

  def index
    @title = "瀏覽使用者"
    @users = User.mostly_active(params[:page])

    respond_to do |format|
      format.html
    end
  end
  
  def show
    @user = User.find(params[:id])
    @user_openids = @user.openids
    @title = "帳號設定"
    unless admin? or logged_in_user?(@user)
      redirect_to profile_path(@user)
    end
  end
  
  def show_by_username
    @user = User.find_by_username(params[:username])
    @title = "#{@user.f}的個人頁面"
    get_content
    render :action => 'show'
  end
  
  def oauth
    # this is a do-nothing action, provided simply to invoke authentication
    # on successful authentication, user will be redirected to 'show'
    # on failure, user will be redirected to 'index'
  end
  
  def google_oauth
    if is_logged_in? && logged_in_user.is_youtube_user?
      flash[:notice] = "您先前已經驗證過 Youtube 帳號了！請至帳號設定頁面查看訊息"
      return redirect_to('/')
    end
    request_token = get_consumer.get_request_token(
      {:oauth_callback => "http://railscode.mine.nu/authsub" },
      {:scope => "http://gdata.youtube.com"})
    
    # Keep the secret
    session[:oauth_secret] = request_token.secret
    # Redirect to Google for authorization
    redirect_to request_token.authorize_url
  end

  # User authorized us at Google site
  def authsub
    # Recreate the (now authorized) request token
    request_token = OAuth::RequestToken.new(get_consumer, params[:oauth_token],session[:oauth_secret])
    # Swap the authorized request token for an access token                                        
    access_token = request_token.get_access_token(
                      {:oauth_verifier => params[:oauth_verifier]})
    body = access_token.get("http://gdata.youtube.com/feeds/api/users/default").body
    oauth_user = Nokogiri::XML.parse(body).search("author").children.first.text
    user = User.find_by_youtube_username(oauth_user)
    if user
      if is_logged_in? && !is_me?(user)
        flash[:error] = "抱歉，這個Youtube帳戶 #{user.youtube_username} 已經連結至其他使用者了！"
        redirect_back_or_default('/')
      else
        user.update_attributes(
          :oauth_token => access_token.token, 
          :oauth_secret => access_token.secret)
        session[:oauth_token] = access_token.token
        session[:oauth_secret] = access_token.secret
        self.logged_in_user = user
        self.logged_in_user.increment!(:signin_count)
        flash[:notice] = "嗨 #{oauth_user}，你已經透過Youtube帳戶登入"
        return redirect_to('/')
      end
    else
      if is_logged_in?
        logged_in_user.update_attributes(
          :oauth_token => access_token.token, 
          :oauth_secret => access_token.secret, 
          :youtube_username => oauth_user)
        flash[:notice] = "已驗證你的Youtube帳號 #{oauth_user}，下次你可以使用這個帳號登入"
        return redirect_to user_path(logged_in_user)
      else
        @user = User.new({
          :oauth_token => access_token.token, 
          :oauth_secret => access_token.secret, 
          :youtube_username => oauth_user})
        flash[:notice] = "嗨 #{oauth_user}，你已完成Google帳戶驗證，接下來我們需要您填寫一些基本資料"
        render :action => 'new'
      end
    end
  end
  
  def new
    @title = "註冊 #{app_name} 帳戶"
    @user = User.new
    if is_logged_in? || (params[:fb_user] && !facebook_user) || (params[:fg_user] && !fbgraph_user) || (params[:fsq_user] && !foursquare_user)
      return redirect_to('/')
    end
    if params[:fb_user] && facebook_user
      @signup_value1 = facebook_user.username
      @signup_value2 = facebook_user.first_name
      @signup_value3 = facebook_user.last_name
      @signup_value4 = facebook_user.email
    elsif params[:fg_user] && fbgraph_user
      @signup_value1 = fbgraph_user.username
      @signup_value2 = fbgraph_user.first_name
      @signup_value3 = fbgraph_user.last_name
      @signup_value4 = fbgraph_user.email
    elsif params[:fsq_user] && foursquare_user
      @signup_value1 = foursquare_user.username
      @signup_value2 = foursquare_user.first_name
      @signup_value3 = foursquare_user.last_name
      @signup_value4 = foursquare_user.email
    else
      @signup_value1 = @signup_value2 = @signup_value3 = @signup_value4 = ""
    end
  end
  
  def create
    @title = "註冊 #{app_name} 帳戶"
    @user = User.new(params[:user])
    @check = params[:check]
    send_mail = !global_prefs.nil? && global_prefs.email_verifications?
    #If signup with Yahoo! ID or Twitter OAuth
    return unless request.post?
      if (@user.yahoo_userhash || @user.twitter_id || @user.wll_uid || @user.youtube_username) != nil
        @user.hashed_password = ""
      # joining via old Facebook connect: link to FB account and set a random password
      elsif params[:fb_user]
        return redirect_to('/') unless facebook_user
        @user.fb_uid = facebook_user.uid
        @user.hashed_password = ""
      # joining via Facebook Graph OAuth
      elsif params[:fg_user]
        return redirect_to('/') unless fbgraph_user
        @user.fb_user_uid = session[:fbgraph_uid]
        @user.fb_access_token = session[:fbgraph_session]
        @user.hashed_password = ""
      # joining via Foursquare OAuth
      elsif params[:fsq_user]
        return redirect_to('/') unless foursquare_user
        @user.foursquare_uid = foursquare_user.id
        @user.foursquare_token = session[:fsq_session]
        @user.hashed_password = ""
      end
    if @check && (!params[:register_with_oauth] && !params[:oauth_token])
      if verify_recaptcha(@user) && @user.save!
        if params[:fb_user] || params[:fg_user] || params[:fsq_user] || @user.twitter_id || @user.wll_uid || @user.youtube_username || !send_mail
          @user.activate
          self.logged_in_user = @user
          flash[:notice] = "歡迎 #{@user.f}，您已在 #{app_name} 上完成註冊！"
          return redirect_to index_url
        else
          UserNotifier.deliver_signup_notification(@user)
        end
      elsif @user.identity_url                                                
        render :action => 'fillup'  
      else
        @user.clear_password!
        render :action => 'new' 
      end
    # Signup or Login from Linkedin OAuth
    elsif params[:register_with_oauth] || params[:oauth_token]
      @user.save do |result|
        if result
          @user.hashed_password = ""
          @user.activation_code = ""
          @user.activated_at = Time.now
          UserSession.create(@user)
          self.logged_in_user = @user
          self.logged_in_user.increment!(:signin_count)
          flash[:notice] = "歡迎 #{@user.f}，您已在 #{app_name} 上完成註冊！"
          return redirect_to index_url
        else
          unless @user.oauth_token.nil?
            @user = User.find_by_oauth_token(@user.oauth_token)
            unless @user.nil?
              if is_logged_in? && !is_me?(@user)
                flash[:error] = "抱歉，這個 LinkedIn 帳戶已經與其他帳戶連結了"
                return redirect_back_or_default('/')
              else # log the user in vis LinkedIn account
                UserSession.create(@user)
                # update the user's data from LinkedIn API
                @user.populate_oauth_user
                @user.populate_child_models
                # log the user in
                self.logged_in_user = @user
                self.logged_in_user.increment!(:signin_count)
                flash[:notice] = "嗨 #{@user.f}，你已經透過 Linkedin 帳號登入"
                return redirect_back_or_default('/')
              end
            else # @user == nil
              if is_logged_in?
                #UserSession.create(logged_in_user)
                #logged_in_user.populate_oauth_user
                #logged_in_user.populate_child_models
                flash[:notice] = "你的帳戶已與 LinkedIn 建立連接。下次您可以使用這個帳號來登入"
                return redirect_back_or_default('/')
              else
                @user = User.new
                return redirect_to(:controller => 'users', :action => 'new', :linkedin_user => 1)
              end
            end
          else
            redirect_back_or_default signup_url
          end
        end
      end
    else
      @user.clear_password!
      flash[:error] = "你必須填滿所有的欄位。"
      render :action => 'new'
    end
    rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @title = "編輯帳號資料"
    @user = logged_in_user
    @user_openids = @user.openids
  end

  def update
    @user = User.find(params[:id])
    return unless request.put?
    attribute = params[:attribute]
    case attribute
      when "姓名"
        try_to_update @user, attribute
      when "電子郵件"
        try_to_update @user, attribute
      when "其他帳號"
        try_to_update @user, attribute
      when "密碼"
      if @user.hashed_password.blank?
        try_to_update @user, attribute
      else
        if @user.correct_password?(params)
          try_to_update @user, attribute
        else
          @user.password_errors(params)
          @user.clear_password!
          render :action => 'edit'
        end
      end
      when "安全性問題"
        try_to_update @user, attribute
    end
  end

  def destroy
    @user = User.find(params[:id])
    if @user == logged_in_user
      if verify_recaptcha && @user.update_attribute(:enabled, false)
        logout_killing_session!
        redirect_to login_path
        flash[:notice] = "你的帳號已經停用。若要重新啟動你的帳號，請以之前登記的電子郵件和密碼登入。之後你將可以如同以往一般使用本網站。"
        UserNotifier.deliver_disable(@user)
      else
        flash[:error] = "停用使用者帳號時出現問題，請輸入正確的驗證碼！"
        redirect_to user_path(logged_in_user)
      end
    elsif admin?
      if @user.update_attribute(:enabled, false)
        flash[:notice] = "你已經將使用者 #{@user.f} 的帳號凍結"
        redirect_to admin_users_path
      else
        flash[:error] = "停用使用者帳號時出現問題"
        redirect_to admin_users_path
      end
    else
      flash[:error] = "你沒有權限執行這個動作！"
      redirect_to index_url
    end
  end

  def enable
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, true)
      @user.update_attribute(:reactivation_code, nil)
      @user.update_attribute(:reactivated_at, Time.now)
      flash[:notice] = "使用者 #{@user.f} 的帳號已經啟用"
    else
      flash[:error] = "啟用使用者帳號時出現問題"
    end
    redirect_to admin_users_path
  end
  
  def delete_icon
    respond_to do |format|
      user = admin? ? User.find(params[:user_id]) : logged_in_user
      user.update_attribute :icon, nil
      format.js { render(:update){|page| page.visual_effect :puff, 'avatar_edit'}}
    end      
  end

  def yahooLogin
    ya = YahooBbAuth.new()
    redirect_to ya.get_auth_url('', true)
  end

  def yahooAuth
    @title = "申請 Cateplaces 帳號"
    ya = YahooBbAuth.new()
    userhash = params[:userhash]
    if !ya.verify_sig(request.request_uri)
      redirect_to :controller => :error
    return
    end
    @user = User.find_by_yahoo_userhash(userhash)
    if @user == nil
      @user = User.new(:yahoo_userhash => userhash)
      flash[:notice] = "Yahoo! 帳號認證成功，現在我們需要您填寫個人資訊來註冊帳號"
      render :action => 'new'
    else
      session[:user] = @user
      @user.update_attribute(:last_login_at, Time.now)
      @user.increment!(:signin_count)
      flash[:notice] = "嗨，#{@user.f}，你已經使用 Yahoo! ID 登入"
      redirect_to index_url
    end
  end
  
  def liveLogin
    redirect_to WindowsLiveLogin.login_url
  end
  
  def liveLogout
    redirect_to WindowsLiveLogin.logout_url
  end

  def liveAuth
    tmp, get_params = request.request_uri.split("?")
    action = nil

    if get_params
      get_params.split("&").each do |p|
        key, content = p.split("=")
        if key == "action"
          action = content
          break
        end
      end
    end

    case action
    when "logout"
      logout_killing_session!
      flash[:notice] = "您已經成功登出網站"
      redirect_to login_url
      return
    when "clearcookie"
      redirect_to "/images/wll-clear-cookie.gif"
      return
    else
      @wll = WindowsLiveLogin.new()
      if !@wll.process_token(params[:stoken])
        @error = true
      else
        @user = User.find_by_wll_uid(@wll.uid)
        if !@user # User can not be found
          if is_logged_in?
            logged_in_user.update_attributes(
              :wll_uid => @wll.uid, 
              :wll_name => Digest::MD5.hexdigest(@wll.uid).slice(0, 7))
            flash[:notice] = "已驗證您的 Live ID 帳號，下次您可以使用這個帳號來登入"
            return redirect_to user_path(logged_in_user)
          else
            @user = User.new(:wll_uid => @wll.uid,
                             :wll_name => Digest::MD5.hexdigest(@wll.uid).slice(0, 7))
            flash[:notice] = "Windows Live ID認證成功，現在我們需要您填寫個人資訊來註冊帳號"
            render :action => 'new'
          end
        else
          if is_logged_in? && !is_me?(@user)
            flash[:error] = "抱歉，這個 Live ID 帳號已經被使用了"
            redirect_back_or_default('/')
          else
            session[:user] = @user
            @user.increment!(:signin_count)
            flash[:notice] = "嗨，#{@user.f}，你已經使用 Windows Live ID 登入"
            redirect_to index_url
          end
        end
      end
    end
  end

  def get_content
    @entries = @user.entries.find(:all, :limit => 3, :order => 'created_at DESC')
    @photos = @user.photos.find(:all, :limit => 3, :order => 'created_at DESC')
    @flickr_feed = @user.flickr_feed if @user.flickr_id
  end
  
  #Twitter API method
  def update_twitter_status
    if self.update_twitter_status!(params[:status_message])
      flash[:notice] = 'status update sent'
    else
      flash[:error] = 'status update problem'
    end
    redirect_to index_url
  end

  def partialfriends
    if (request.xhr?)
      @friends = self.friends()
      render :partial => 'users/twitter_friend', :collection => @friends, :layout => false
    else
      flash[:error] = 'method only supporting XmlHttpRequest'
      redirect_to index_url
    end
  end

  def partialfollowers
    if (request.xhr?)
      @followers = self.followers()
      render :partial => 'users/twitter_friend', :collection => @followers, :as => :friend, :layout => false
    else
      flash[:error] = 'method only supporting XmlHttpRequest'
      redirect_to index_url
    end
  end

  def partialmentions
    if (request.xhr?)
      @messages = self.mentions()
      render :partial => 'users/twitter_status', :collection => @messages, :as => :status, :layout => false
    else
      flash[:error] = 'method only supporting XmlHttpRequest'
      redirect_to index_url
    end
  end

  def partialdms
    if (request.xhr?)
      @messages = self.direct_messages()
      render :partial => 'users/direct_message', :collection => @messages, :as => :direct_message, :layout => false
    else
      flash[:error] = 'method only supporting XmlHttpRequest'
      redirect_to index_url
    end
  end
  
protected

  def init_member
    begin
      #oauth_user = params[:id] unless params[:id].nil?
      #oauth_user = params[:user_id] unless params[:user_id].nil?
      @user = User.find_by_screen_name(logged_in_user.screen_name)
      raise ActiveRecord::RecordNotFound unless @user
    rescue
      flash[:error] = "您先前已經驗證過 Twitter 帳號了！請至帳號設定頁面查看訊息"
      redirect_back_or_default('/')
      return false
    end
  end
  
  def access_check
    return if logged_in_user.id == @user.id
    flash[:error] = "抱歉，因權限關係您無法執行這項活動"
    redirect_back_or_default('/')
    return false    
  end 

private
  
    def setup
      @body = "user"
    end
  
    def try_to_update(user, attribute)
      if @user.update_attributes(params[:user])
        flash[:notice] = "你的 #{attribute} 資料已經更新"
        redirect_to edit_user_path(logged_in_user)
      else
        @user.clear_password!
        render :action => 'edit'
      end
    end
end