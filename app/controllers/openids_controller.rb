class OpenidsController < ApplicationController
  before_filter :login_required
  skip_before_filter :verify_authenticity_token

  def new
    @title = "新增 OpenID 帳號"
    user_openid = UserOpenid.new
  end

  def create
    open_id_authentication(params[:openid_url])
  end

  def destroy
    user_openid = logged_in_user.openids.find(params[:id])
    if logged_in_user.openids.count > 1
      if user_openid.destroy
        flash[:notice] = "你選擇的 OpenID 帳號已經刪除" 
      else
        flash[:error] = "刪除 OpenID 帳號失敗"
      end
    else
        flash[:notice] = "你只有 1 個 OpenID 帳號"
    end
      respond_to do |format|
        format.html { redirect_to user_path(logged_in_user) }
      end   
  end

  protected

  def open_id_authentication(openid_url)
    authenticate_with_open_id(openid_url, :required => [:nickname, :email]) do |result, identity_url, registration|
      if result.successful?
        identity_url = identity_url.gsub(%r{/$},'')
        logged_in_user_openid = UserOpenid.new(:user_id => logged_in_user.id, :openid_url => identity_url )
        respond_to do |format|
          format.html{
            if logged_in_user_openid.save
              redirect_to user_path(logged_in_user)
              flash[:notice] = "已成功新增一個 OpenID 帳號"
            else
              flash[:notice] = "抱歉！這個 OpenID 帳號已經有人使用了"
              redirect_to :action => 'new'
            end
             }
        end
      else
        flash[:notice] = "你輸入的 OpenID 帳號是無效的"
        redirect_to :action => 'new'
      end
    end
  end

end
