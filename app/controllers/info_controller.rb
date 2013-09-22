class InfoController < ApplicationController
  before_filter :login_required, :only => [:show, :edit, :update]
  
  def index
    redirect_to profile_path(logged_in_user)
  end
  
  def show
    @user = User.find(params[:id])
    @title = "基本資訊"
  end

  def edit
    @title = "編輯基本資訊"
    @user = logged_in_user
    @user.info ||= Info.new
    @info = @user.info
    rescue ActiveRecord::RecordNotFound
    redirect_to :action => 'index'
  end
  
  def update
    @user = logged_in_user
    @user.info ||= Info.new
    @info = @user.info
    if request.put?
      if @user.info.update_attributes(params[:info])
        flash[:notice] = "您的基本資訊已經更新"
        redirect_to profile_path(logged_in_user)
      else
        render :action => 'edit'
      end
    end
    rescue ActiveRecord::RecordNotFound
    redirect_to :action => 'edit'
  end

end
