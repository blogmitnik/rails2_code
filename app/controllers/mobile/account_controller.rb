class Mobile::AccountController < AccountController
  layout 'mobile'
  
  def authenticate
    self.logged_in_user = User.authenticate(params[:user][:username], 
                                            params[:user][:password])
    if is_logged_in?
      flash[:notice] = "您已經成功登入"
      redirect_to mobile_index_url
    else
      flash[:error] = "您輸入的使用者名稱或密碼有錯誤"
      redirect_to :action => 'login'
    end
  end
  
  def logout
    reset_session
    flash[:notice] = "您已經成功登出"
    redirect_to mobile_index_url
  end
end