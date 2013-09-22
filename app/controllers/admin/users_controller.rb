class Admin::UsersController < ApplicationController

  before_filter :login_required, :admin_required

  def index
    @title = "使用者管理"
    @users = User.paginate(:all, :page => params[:page], :order => :username)
  end

  def update
    @user = User.find(params[:id])
    if logged_in_user?(@user)
      flash[:error] = "錯誤的執行動作"
    else
      @user.toggle!(params[:task])
      flash[:notice] = "#{CGI.escapeHTML @user.username} 帳號資料已經更新"
    end
    respond_to do |format|
      format.html { redirect_to :back }
    end
  end
end