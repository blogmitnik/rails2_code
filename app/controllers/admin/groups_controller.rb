class Admin::GroupsController < ApplicationController

  before_filter :login_required, :admin_required
  
  def index
    @title = "管理群組"
    @groups = Group.paginate(:all, :page => params[:page], :order => :name)
    
    respond_to do |format|
      format.html
    end
  end
  
  def destroy
    @group = Group.find_by_url_key(params[:id]) rescue nil
    @group.destroy
    respond_to do |format|
      flash[:notice] = "你已成功刪除#{@group.nanme}群組"
      format.html { redirect_to(admin_groups_path) }
    end
  end
end
