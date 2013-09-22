class FbOauthController < ApplicationController
  
  def callback
    auth = request.env['omniauth.auth']
    token = auth['credentials']['token']
    session[:fbgraph_session] = token
    session[:fbgraph_uid] = auth['uid']
    logger.debug "facebook session in connect: #{fbgraph_session.inspect}"
    #client = FBGraph::Client.new(:client_id => GRAPH_APP_ID, :secret_id => GRAPH_SECRET, :token => token)
    #client.inspect
    #user = client.selection.me.info!
    #client.selection.user(user[:id]).feed.publish!(:message => 'test message', :name => 'test name')
    #render :json => client.selection.me.info!
    
    if fbgraph_user
      user = User.find_by_fb_user_uid(auth['uid'])
      if user == nil
        if is_logged_in? # authorize from user setting page
          logged_in_user.update_attributes(
            :fb_user_uid => auth['uid'],
            :fb_access_token => token)
          flash[:notice] = "你的帳戶已與 Facebook 建立連接。下次您可以使用這個帳號來登入"
          return redirect_back_or_default('/')
        else
          # joining Facebook user, send to fill in username/email to create user
          return redirect_to(:controller => 'users', :action => 'new', :fg_user => 1)
        end
      else
        if is_logged_in? && !is_me?(user)
          flash[:error] = "抱歉，這個 Facebook 帳戶已經與其他帳戶連結了"
          session[:fbgraph_session] = session[:fbgraph_uid] = nil
          return redirect_back_or_default('/')
        else
          # if fb_user_uid found in user record, log the user in
          self.logged_in_user = user
          self.logged_in_user.increment!(:signin_count)
          flash[:notice] = "嗨 #{fbgraph_user.first_name}，你已經透過 Facebook 帳戶登入"
          return redirect_to('/')
        end
      end
    end
    render(:nothing => true)
  end
  
end
