class Groups::News::CommentsController < ApplicationController
    include UserMethods
    include GroupMethods
    before_filter :get_user
    before_filter :get_group
    before_filter :setup
    before_filter :no_comment

    def index
      @title = "#{@news_item.title} 的全部回應"
      @wall_comments = @news_item.wall_comments.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
      
      respond_to do |format|
          format.html {render}
          format.rss {render :layout=>false}
      end
    end  

    protected

    def setup
        @news_item = NewsItem.find_by_url_key(params[:news_id]) || NewsItem.find(params[:news_id])
        @can_participate = @news_item? is_logged_in? && @group.can_participate?(logged_in_user) : false
    end
    
    def no_comment
      if @news_item.wall_comments.empty?
        redirect_to group_news_path(@group, @news_item)
      end
    end

end
