class Profile::ActivitiesController < ApplicationController
  before_filter :setup
  
  def index
    @title = "#{@user.name} 的動態消息"
    respond_to do |format|
      format.html { render }
      format.rss { render :layout => false }
    end
  end
  
  protected
  
  def setup
    @user = User.find(params[:profile_id])
    respond_to do |wants|
      wants.html do
        @activities = @user.recent_activity.paginate(:page => params[:page], :per_page => 30, :order => 'created_at desc')
      end
      wants.rss do 
        @activities = @user.recent_activity.paginate(:page => params[:page], :per_page => 30, :order => 'created_at desc')
        render :layout => false
      end
    end
  end

end