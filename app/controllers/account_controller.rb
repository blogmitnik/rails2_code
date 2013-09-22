class AccountController < ApplicationController
  before_filter :protect, :only => :index
  before_filter :check_too_many_signin_failures, :only => :authenticate
  before_filter :ssl_requirement, :only => [:login, :authenticate]
  
  def openid_login
    @title = "OpenID 登入"
    if is_logged_in?
      flash[:notice] = "你目前已經是登入的狀態了"
      redirect_to index_url
    end
  end
  
  def openid_authenticate
    if using_open_id?
      open_id_authentication(params[:openid_url])
    else
      flash[:notice] = "請輸入你的 OpenID 帳號"
      redirect_to :action => 'openid_login'
    end
  end
  
  def login
    @title = "使用者登入"
    if is_logged_in?
      flash[:notice] = "你目前已經是登入的狀態了"
      redirect_to index_url
    end
  end
  
  def authenticate
    @title = "使用者登入"
    send_mail = !global_prefs.nil? && global_prefs.email_verifications?
    return redirect_to('/') unless request.post?
      self.logged_in_user = User.authenticate(params[:user][:email], params[:user][:password])
      # If current login account has disabled and email/password match the record
      if logged_in_user and !logged_in_user.reactivation_code.nil?
        flash[:notice] = "歡迎回來，我們已經發送一封重新啟用信至您的信箱 #{logged_in_user.email}"
        render :action => 'login'
        flash.clear
        UserNotifier.deliver_reactivation(logged_in_user)
        return
      end
      if is_logged_in?
        @user = User.find(logged_in_user)
        if params[:user][:remember_me] == "1"
          self.logged_in_user.remember_me
          cookies[:auth_token] = { :value => self.logged_in_user.remember_token , :expires =>self.logged_in_user.remember_token_expires_at }
        end
        logged_in_user.increment!(:signin_count)
        flash[:notice] = "嗨，#{logged_in_user.name} 歡迎回來"
        redirect_to_forwarding_url
      else # Can not Log in the User
        u = User.find_by_email(params[:user][:email])
        if u and u.activated_at.nil?
          flash[:notice] = "您的 #{app_name} 帳戶尚未啟用，快到您的電郵信箱啟用帳號"
        elsif u and !u.hashed_password.blank?
          flash[:notice] = %(#{app_name} 的密碼有大小寫之分。請檢查您的 CAPS 鍵。您可以<a href="/password_reset">在此重設你的密碼</a>。)
          SigninFailure.create(:email => params[:user][:email].downcase, :ip => request.remote_ip)
        else
          flash[:error] = %(您登入的 Email 帳號並不存在！是否要<a href="/signup">註冊 #{app_name} 帳戶</a>？)
        end
        render :action => 'login'
        flash.clear
      end
  end

  def logout
    if request.post? or facebook_user
      logout_killing_session!
      flash[:notice] = "您已經成功登出網站"
      redirect_to login_url
    else
      flash[:notice] = "請用正常的方式登出網站"
      redirect_to index_url
    end
  end
  
  def forgot_password
    @title = "重設密碼"
    if is_logged_in?
      flash[:notice] = "你目前已經是登入的狀態"
      redirect_to index_url
    end
    return unless request.post?
    if @user = User.find_by_email(params[:user][:email])
      @user.forgot_password
      @user.save
      UserNotifier.deliver_forgot_password(@user) if @user.password_forgotten
      flash[:notice] = "有一封電子郵件已經傳送到 #{@user.email}，說明如何取得你的新密碼。"
      redirect_to index_url
    else
      flash.now[:notice] = "您輸入的電子郵件尚未註冊。"
    end
  end
  
  def reset_password
    @page_title = "重設密碼"
    @user = User.find_by_pw_reset_code(params[:id]) rescue nil
    unless @user
      flash[:error] = "這個連結已經失效，若忘記密碼請重新輸入Email地址。"
      redirect_to :action => 'forgot_password'
    return
    end
    return unless request.post?
    if @user.update_attributes(params[:user])
      @user.reset_password
      self.logged_in_user = @user
      flash[:notice] = "密碼已成功重設，你現在已經登入網站"
      redirect_to index_url
    end
  end
  
  def activate
    @user = User.find_by_activation_code(params[:id])
    if @user and @user.activate
      self.logged_in_user = @user
      redirect_to index_url
      flash[:notice] = "#{@user.f}，歡迎！你的帳號現在已成功建立。"
      @user.update_attribute(:last_login_at, Time.now)
      #UserNotifier.deliver_activation(@user)
    else
      redirect_to login_url
      flash[:error] = "抱歉！你輸入的是無效的網址"
    end
  end
  
  def reactivate
    @user = User.find_by_reactivation_code(params[:id])
    if @user and @user.reactivate
      @user.update_attribute(:enabled, true)
      @user.update_attribute(:reactivation_code, nil)
      @user.update_attribute(:last_login_at, Time.now)
      self.logged_in_user = @user
      redirect_to index_url
      flash[:notice] = "嗨，#{@user.f}，你的帳號已經重新啟用。"
    else
      redirect_to login_url
      flash[:error] = "抱歉！你輸入的是無效的網址"
    end
  end
  
  
  protected
  
    def open_id_authentication(openid_url)
      authenticate_with_open_id(openid_url, :required => [:nickname, :email]) do |result, identity_url, registration|
        if result.successful?
          identity_url = identity_url.gsub(%r{/$},'')
          @user_openid = UserOpenid.find_by_openid_url(identity_url)
          @user = User.find_or_initialize_by_identity_url(identity_url)
          if @user_openid && @user_openid.user.enabled
            self.logged_in_user = @user_openid.user
            successful_login
          elsif @user_openid && !@user_openid.user.enabled
            complete_fillup
            UserNotifier.deliver_reactivation(@user_openid.user)
          else
            @user = User.find_or_initialize_by_identity_url(identity_url)
            if @user.new_record?
              @user.username = registration['nickname']
              @user.email = registration['email']
              @user.identity_url = identity_url
              render :template => "users/new"
            else
              self.logged_in_user = @user
              successful_login
            end
          end
        else
          failed_login result.message
        end
      end
    end
    
    def complete_fillup
      render :template => "users/fillup"
    end
    
    def successful_login
      @user = User.find(logged_in_user)
      if params[:remember_me] == "1"
        self.logged_in_user.remember_me
        cookies[:auth_token] = { :value => self.logged_in_user.remember_token , :expires =>self.logged_in_user.remember_token_expires_at }
      end
      @user.update_attribute(:last_login_at, Time.now)
      @user.increment!(:signin_count)
      flash[:notice] = "嗨，#{logged_in_user.f}。你已經透過 OpenID 帳號登入"
      redirect_back_or_default('/')
    end
    
    def failed_login(message = "OpenID 帳號登入失敗")
      flash[:error] = message
      redirect_to openid_login_url
    end
  
  
  private
  
    def check_too_many_signin_failures
      if SigninFailure.count('*',
        :conditions => ['email = ? and ip = ? and created_at >= ?', params[:user][:email].downcase, request.remote_ip, 15.minutes.ago]) > 3
        render :text => "你的登入失敗次數已超過系統限制，請於15分鐘之後再次嘗試登入", :layout => true
        return false
      end
    end

end
