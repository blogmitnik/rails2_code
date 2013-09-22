class AcademicController < ApplicationController
  before_filter :login_required, :only => [:show, :edit, :update]

  def index
    redirect_to profile_path(logged_in_user)
  end

  def show
    @user = User.find(params[:id])
    @title = "學歷和工作經驗"
  end

  def edit
    @title = "編輯學歷和工作經驗"
    @user = logged_in_user
    @user.academic ||= Academic.new
    @academic = @user.academic
    rescue ActiveRecord::RecordNotFound
    redirect_to :action => 'index'
  end

  def update
    @user = logged_in_user
    @user.academic ||= Academic.new
    @academic = @user.academic
    if request.put?
      if @user.academic.update_attributes(params[:academic])
        flash[:notice] = "您的學歷和工作經驗已經更新"
        redirect_to profile_path(logged_in_user)
      else
        render :action => 'edit'
      end
    end
    rescue ActiveRecord::RecordNotFound
    redirect_to :action => 'edit'
  end

end
