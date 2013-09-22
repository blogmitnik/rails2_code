class Groups::ActivitiesController < ApplicationController
  include UserMethods
  include GroupMethods
  
  before_filter :get_user
  before_filter :get_group

  def index
    @title = "#{@group.name} 的動態消息"
    @activities = @group.activities.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE, :order => 'created_at desc')
    respond_to do |format|
      format.html { render }
      format.rss { render :layout => false }
    end
  end

end