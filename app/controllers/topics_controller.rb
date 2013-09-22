class TopicsController < ApplicationController
  include ForumMethods
  before_filter :find_forum
  before_filter :find_topic, :except => :index  
  before_filter :login_required, :except => [:index, :show]  
  before_filter :authorize_new, :only => [:new, :create]
  before_filter :authorize_edit, :only => [:edit, :update, :destroy]
  before_filter :authorize_view, :only => [:show]
  
  caches_formatted_page :rss, :show
  cache_sweeper :posts_sweeper, :only => [:create, :update, :destroy]

  def index
    @title = "#{@forum.name} 討輪串"
    respond_to do |format|
      format.html { redirect_to get_forum_redirect }
      format.xml do
        @per_page = 30
        @topics = Topic.paginate_by_forum_id(@forum.id, :order => 'sticky desc, replied_at desc', :page => params[:page], :per_page => @per_page)
        render :xml => @topics.to_xml
      end
    end
  end
  
  def show
    @title = "#{@topic.title}"
    respond_to do |format|
      format.html do
        update_last_login_at
        # keep track of when we last viewed this topic for activity indicators
        (session[:topics] ||= {})[@topic.id] = Time.now.utc if is_logged_in?
        # authors of topics don't get counted towards total hits
        @topic.hit! unless is_logged_in? and @topic.user == logged_in_user
        @per_page = 30
        @posts = @topic.posts.find(:all, :include => :user).paginate(:page => params[:page], :per_page => @per_page)
        #User.find(:all, :conditions => ['id IN (?)', @posts.collect { |p| p.user_id }.uniq]) unless @posts.blank?
        @page_title = @topic.title
        #@monitoring = is_logged_in? && !Monitorship.count(:id, :conditions => ['user_id = ? and topic_id = ? and active = ?', logged_in_user.id, @topic.id, true]).zero?
        render_topic_view
      end
      format.xml do
        render :xml => @topic.to_xml
      end
      format.rss do
        @posts = @topic.posts.find(:all, :order => 'created_at desc', :limit => 30)
        render :action => 'show', :layout => false
      end
    end
  end

  def new
    @title = "新增討輪串"
    @topic = Topic.new
    render_topic_view
  end

  def edit
    @title = "編輯討論串內容"
    render_topic_view
  end

  def create
    @title = "新增討輪串"
    Topic.transaction do
      @topic = @forum.topics.build(params[:topic])
      assign_protected
      @post = @topic.posts.build(params[:topic])
      @post.topic = @topic
      @post.user = logged_in_user
      @topic.body = @post.body
      @topic.save! if @post.valid?
      @post.save! 
    end
    respond_to do |format|
      format.html { redirect_to get_topic_redirect }
      format.xml  { head :created, :location => formatted_forum_topic_url(:forum_id => @forum, :id => @topic, :format => :xml) }
    end
  end
  
  def update
    @title = "編輯討論串內容"
    @topic.attributes = params[:topic]
    assign_protected
    @topic.save!
    respond_to do |format|
      format.html do 
        flash[:notice] = "討論主題已成功更新"
        redirect_to get_topic_redirect
      end
      format.xml  { head 200 }
    end
  end
  
  def destroy
    @topic.destroy
    flash[:notice] = "討論串 '#{@topic.title}' 已成功刪除"
    respond_to do |format|
      format.html { redirect_to get_forum_redirect }
      format.xml  { head 200 }
    end
  end

  protected
  
    def assign_protected
      @topic.user = logged_in_user if @topic.new_record?
      # admins and moderators can sticky and lock topics
      return unless admin? or moderator? or logged_in_user.moderator_of?(@topic.forum)
      @topic.sticky, @topic.locked = params[:topic][:sticky], params[:topic][:locked] 
      # only admins can move
      return unless admin?
      @topic.forum_id = params[:topic][:forum_id] if params[:topic][:forum_id]
    end
    
    def authorized?
      %w(new create).include?(action_name) || @topic.editable_by?(logged_in_user)
    end
    
    def authorize_new
      case @forum.forumable
      when Group
        @group = @forum.forumable
        unless @forum.forumable.can_participate?(logged_in_user)
          if @group.hidden?
            redirect_to index_path
          else
            redirect_to group_path(@forum.forumable)
            flash[:notice] = "你必須是 #{@group.name} 的成員才能建立討論話題"
          end
        end
      else
        unless is_logged_in?
          redirect_to index_path
        end
      end
    end
    
    def authorize_view
      case @forum.forumable
      when Group
        @group = @forum.forumable
        unless @group && (!@group.hidden? || @group.is_member?(logged_in_user) || admin? ||  @group.has_invited?(logged_in_user))
          flash[:notice] = "你無法查看這個頁面內容"
          redirect_back_or_default groups_path
        end
      else
        unless is_logged_in?
          redirect_to index_path
        end
      end
    end
    
    def authorize_edit
      authorized = @topic.editable_by?(logged_in_user)
      unless authorized
        redirect_to index_path
      end
    end
    
    def get_topic_redirect
      case @forum.forumable
      when Group
        group_forum_topic_path(@forum.forumable, @forum, @topic)
      else
        forum_topic_path(@forum, @topic)
      end
    end
    
    def render_topic_view
      case @forum.forumable
      when Group
        @group = @forum.forumable
        render :template => 'groups/topics/' + params[:action]
      else
        render
      end
    end
end