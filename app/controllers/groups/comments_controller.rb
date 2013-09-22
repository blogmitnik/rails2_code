class Groups::CommentsController < ApplicationController
  include GroupMethods
  before_filter :get_group

  def index
    @title = "#{@group.name} 的全部留言"
    @can_participate = is_logged_in? && @group.can_participate?(logged_in_user)
    @user = @group.owner
    @wall_comments = @group.wall_comments.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
    
    respond_to do |format|
      format.html {render}
      format.rss {render :layout=>false}
    end
  end

end
