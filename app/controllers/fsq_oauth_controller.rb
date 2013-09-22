class FsqOauthController < ApplicationController
  
  def callback
    code = params[:code]
    @access_token = foursquare.access_token(code, callback_fsq_oauth_url)
    session[:fsq_session] = @access_token
    
    if foursquare_user
      # if foursquare_uid found in user record, log the user in
      user = User.find_by_foursquare_uid(foursquare_user.id)
      if user == nil
        if is_logged_in? # authorize from user setting page
          logged_in_user.update_attributes(
            :foursquare_uid => foursquare_user.id,
            :foursquare_token => @access_token)
          flash[:notice] = "你的帳戶已與 Foursquare 建立連接。下次您可以使用這個帳號來登入"
          return redirect_back_or_default('/')
        else
          # joining foursquare user, send to fill in username/email to create user
          return redirect_to(:controller => 'users', :action => 'new', :fsq_user => 1)
        end
      else # user record found
        if is_logged_in? && !is_me?(user)
          flash[:error] = "抱歉，這個 Foursquare 帳戶已經與其他帳戶連結了"
          session[:fsq_session] = nil
          return redirect_back_or_default('/')
        else
          self.logged_in_user = user
          self.logged_in_user.increment!(:signin_count)
          flash[:notice] = "嗨 #{foursquare_user.first_name}，你已經透過 Foursquare 帳戶登入"
          return redirect_back_or_default('/')
        end
      end
    end
    render(:nothing => true)
  end
  
end
