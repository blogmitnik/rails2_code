class Admin::MemberStoriesController < Admin::BaseController
  include NewsItemMethods
  before_filter :setup
  before_filter :get_news_item, :only => [:show, :update, :edit, :destroy]
  
  uses_tiny_mce(:options => GlobalConfig.advanced_mce_options,
                :raw_options => GlobalConfig.raw_mce_options, 
                :only => [:new, :create, :edit, :update])
                
  def index
    @title = "新聞訊息"
    @news_items = @widget.news_items.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @news_items }
      format.json do
        root_part = admin_member_stories_path + '/' 
        render :json => autocomplete_urls_json(@news_items, root_part)
      end
    end
  end

  def show
    @title = "#{@news_item.title}"
    @user = logged_in_user
    render
  end

  def new
    @title = "撰寫新聞訊息"
    @news_item = @widget.news_items.build
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @news_item }
    end
  end

  def edit
    @title = "編輯新聞訊息"
    render
  end

  def create
    @title = "撰寫新聞訊息"
    @news_item = @widget.news_items.build(params[:news_item])
    @news_item.creator = logged_in_user
    saved = @news_item.save

    respond_to do |format|
      if saved
        flash[:notice] = "新聞文章已成功建立"
        format.html { redirect_to admin_member_stories_url }
        format.xml  { render :xml => @news_item, :status => :created, :location => @widget }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @news_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @news_item.update_attributes(params[:news_item])
        flash[:notice] = "新聞文章 '#{@news_item.title}' 已成功更新"
        format.html { redirect_to admin_member_stories_url }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @news_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @news_item.destroy
    flash[:notice] = "新聞文章 '#{@news_item.title}' 已成功刪除"
    respond_to do |format|
      format.html { redirect_to admin_member_stories_url }
      format.xml  { head :ok }
    end
  end

  private

  def setup
    @widget = Widget.find_or_create_by_name(:member_stories)
  end
 
end
