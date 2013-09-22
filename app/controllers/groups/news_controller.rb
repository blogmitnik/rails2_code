class Groups::NewsController < ApplicationController
  include GroupMethods
  include NewsItemMethods

  before_filter :login_required, :except => [:index, :show]
  before_filter :get_group
  before_filter :setup
  before_filter :authorization_required, :only => [:new, :edit, :create, :update, :destroy] 
  before_filter :get_news_item, :except => [:new, :create, :index]

  uses_tiny_mce(:options => GlobalConfig.news_mce_options,
                :only => [:new, :create, :edit, :update])
                
  def index
    @title = "新聞訊息"
    @news = @group.news_items.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @news_items }
    end
  end

  def show
    @title = "#{@news_item.title}"
    @user = logged_in_user
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @news_item }
    end
  end

  def new
    @title = "建立新聞訊息"
    @news_item = @group.news_items.build
    respond_to do |format|
      format.html
      format.xml  { render :xml => @news_item }
    end
  end

  def edit
    @title = "編輯新聞訊息"
    respond_to do |format|
      format.html
      format.xml  { render :xml => @news_item }
    end
  end

  def create
    @news_item = @group.news_items.build(params[:news_item])
    @news_item.creator = logged_in_user
    respond_to do |format|
      if @news_item.save
        flash[:notice] = "你已經成功建立新聞訊息"
        format.html { redirect_to(group_news_path(@group, @news_item)) }
        format.xml  { render :xml => @news_item, :status => :created, :location => @news_item }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @news_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @news_item.update_attributes(params[:news_item])
        flash[:notice] = "你已經成功更新新聞訊息"
        format.html { redirect_to(group_news_path(@group, @news_item)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @news_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @news_item.destroy
    flash[:notice] = "新聞訊息 '#{@news_item.title}' 已經成功刪除"
    respond_to do |format|
      format.html { redirect_to(group_news_index_path(@group)) }
      format.xml  { head :ok }
    end
  end
  
  private

  def setup
    @can_participate = @group ? is_logged_in? && @group.can_participate?(logged_in_user) : false
  end

  def permission_denied 
    flash[:error] = "你沒有權限管理這個群組的新聞訊息"
    respond_to do |format|
      format.html do
        redirect_to group_news_index_path(@group)
      end
    end
  end

end
