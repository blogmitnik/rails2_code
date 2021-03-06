class MemberStoriesController < ApplicationController
    include NewsItemMethods
    before_filter :login_required, :except => [:index, :show]
    before_filter :setup
    before_filter :get_news_item, :only => [:show]
    
    def index
      @title = "新聞訊息"
      @news_items = @widget.news_items.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
       
      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @news_items }
      end
    end

    def show
      @title = "#{@news_item.title}"
      @user = logged_in_user
      render
    end
    
    def new
      @news_item = NewsItem.new
      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @news_item }
      end
    end
    
    private
    
    def setup
      @widget = Widget.find_or_create_by_name(:member_stories)
    end
    
end