class RolesController < ApplicationController
  before_filter :admin_required

  def index
    @user = User.find(params[:user_id])
    @all_roles = Role.find(:all)
    @title = "編輯 #{@user.name} 的權限"
  end
  
  def update
    @user = User.find(params[:user_id])
    @role = Role.find(params[:id])
    unless @user.has_role?(@role.name)
      @user.roles << @role
    end
    redirect_to :action => 'index'
  end
  
  def destroy
    @user = User.find(params[:user_id])
    @role = Role.find(params[:id])
    if @user.has_role?(@role.name)
      @user.roles.delete(@role)
    end
    redirect_to :action => 'index'
  end
  
end