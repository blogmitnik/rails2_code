class SpecController < ApplicationController
  before_filter :login_required, :only => [:show, :edit, :update]
  
  def index
    redirect_to profile_path(logged_in_user)
  end
  
  def show
    @user = User.find(params[:id])
    @title = "個人資訊"
  end

  def edit
    @title = "編輯個人資訊"
    @user = logged_in_user
    @user.spec ||= Spec.new
    @spec = @user.spec
    rescue ActiveRecord::RecordNotFound
    redirect_to :action => 'index'
  end
  
  def update
    @user = logged_in_user
    @user.spec ||= Spec.new
    @spec = @user.spec
    if request.put?
      if @user.spec.update_attributes(params[:spec])
        flash[:notice] = "您的個人資訊已經更新"
        redirect_to profile_path(logged_in_user)
      else
        render :action => 'edit'
      end
    end
    rescue ActiveRecord::RecordNotFound
    redirect_to :action => 'edit'
  end

end
