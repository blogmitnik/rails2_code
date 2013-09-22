class ProfileController < ApplicationController
  include RssMethods
  before_filter :login_required
  before_filter :load_oauth_user, :only => [ :get_content ]
  prepend_before_filter :get_user, :except => [:index, :show_by_username]
  
  def index
    render :action => 'show'
  end

  def show
    if @user
      @title = "#{@user.name}"
      @per_page = 10
      @wall_comments = @user.wall_comments.paginate(:page => params[:page], :per_page => @per_page)
    else
      flash[:notice] = "你要瀏覽的使用者並不存在"
      redirect_to profile_path(logged_in_user)
    end
    unless @user.active? or admin?
      flash[:error] = "這個使用者的帳號尚未認證"
      redirect_to index_url and return
    end
    get_content
    rescue ActiveRecord::RecordNotFound
    flash[:notice] = "你瀏覽的使用者不存在"
    redirect_to profile_path(logged_in_user)
    
    respond_to do |format|
      format.html
    end
  end
  
  def show_by_username
    @user = User.find_by_username(params[:username])
    @title = "#{@user.name}"
    get_content
    render :action => 'show'
  end
  
  def get_content
    @flickr_feed = @user.flickr_feed if @user.flickr_id
    unless @user.youtube_username.blank?
      begin
        client = YouTubeG::Client.new
        @video = client.videos_by(:user => @user.youtube_username).videos.first
      rescue Exception, OpenURI::HTTPError
      end
    end
    
    begin
      @flickr = @user.flickr_username.blank? ? [] : flickr_images(flickr.people.findByUsername(@user.flickr_username))
    rescue Exception, OpenURI::HTTPError
      @flickr = []
    end
    
    if is_logged_in?
      @friends = @user.friends
      @some_friends = @user.some_friends
      @common_friends = logged_in_user.common_friends_with(@user, :page => params[:page])
      num_friends = User::MAX_DEFAULT_FRIENDS
      @some_common_friends = @common_friends[0...num_friends]
      @blog = @user.blog
      @posts = @blog.posts.paginate(:page => params[:page])
      @galleries = @user.galleries.paginate(:page => params[:page])
      @groups = logged_in_user == @user ? @user.groups : @user.groups_not_hidden
      @some_groups = @groups[0...num_friends]
      @own_groups = logged_in_user == @user ? @user.own_groups : @user.own_not_hidden_groups
      @some_own_groups = @own_groups[0...num_friends]
      @tags = @user.photos.tag_counts(:order => 'name')
      if logged_in_user?(@user)
        @recipient = (logged_in_user.requested_friends + logged_in_user.friends + logged_in_user.pending_friends)
      else
        @recipient = [@user]
      end
    end
    
    if @user.blog_rss          
      @blog_rss = RssMethods::get_rss(@user.blog_rss, 5) rescue nil
    end
    
    if @access_token
      body = @access_token.get("http://gdata.youtube.com/feeds/api/users/default").body
      @oauth_user = Nokogiri::XML.parse(body).search("author").children.first.text
    end
    
    respond_to do |wants|
      wants.html do
        @recent_activity = @user.recent_activity.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE, :order => 'created_at desc')
      end
      wants.rss do 
        @recent_activity = @user.recent_activity.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE, :order => 'created_at desc')
        render :layout => false
      end
    end
  end
  
  def common_friends
    @title = "我和 #{@user.name} 共同的朋友"
    @common_friends = @user.common_friends_with(logged_in_user, :page => params[:page])
    respond_to do |format|
      format.html
    end
  end
  
  def groups
    @groups = logged_in_user == @user ? @user.groups : @user.groups_not_hidden
    @some_groups = @groups.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
    @title = "#{@user.name} 加入的群組"
    
    respond_to do |format|
      format.html
    end
  end
  
  def admin_groups
    @groups = logged_in_user == @user ? @user.own_groups : @user.own_not_hidden_groups
    @some_groups = @groups.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
    @title = "#{@user.name} 建立的群組"
    render :action => :groups
  end
  
  def request_memberships
    @user = User.find(params[:id])
    @requested_memberships = @user.requested_memberships
  end
  
  def invitations
    @user = User.find(params[:id])
    @invitations = @user.invitations
  end
  
  private
  
  def get_user
    @user = User.find(params[:id])
  end

end
