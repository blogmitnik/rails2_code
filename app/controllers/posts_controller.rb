class PostsController < ApplicationController
  before_filter :get_instance_vars
  before_filter :get_post, :except => [:index, :new, :create, :monitored, :search]
  before_filter :login_required, :except => [:index, :monitored, :show, :search]
  before_filter :check_blog_mismatch, :only => :show
  before_filter :authorize_new, :only => [:create, :new]
  before_filter :authorize_edit, :only => [:edit, :update, :destroy]
  @@query_options = { :select => "#{ForumPost.table_name}.*, #{Topic.table_name}.title as topic_title, #{Forum.table_name}.name as forum_name", 
                      :joins => "inner join #{Topic.table_name} on #{ForumPost.table_name}.topic_id = #{Topic.table_name}.id inner join #{Forum.table_name} on #{Topic.table_name}.forum_id = #{Forum.table_name}.id" }

  cache_sweeper :posts_sweeper, :only => [:create, :update, :destroy]

  def index
    if blog?
      redirect_to blog_url(@blog)
    else # Show recent posts
      @title = "最近的討論文章"
      conditions = []
      [:user_id, :forum_id, :topic_id].each { |attr| conditions << ForumPost.send(:sanitize_sql, ["#{ForumPost.table_name}.#{attr} = ?", params[attr]]) if params[attr] }
      conditions = conditions.empty? ? nil : conditions.collect { |c| "(#{c})" }.join(' AND ')
      @posts = ForumPost.paginate @@query_options.merge(:conditions => conditions, :page => params[:page], :per_page => @per_page, :count => {:select => "#{ForumPost.table_name}.id"}, :order => post_order)
      @users = User.find(:all, :select => 'distinct *', :conditions => ['id in (?)', @posts.collect(&:user_id).uniq]).index_by(&:id)
      render_posts_or_xml
    end
  end
  
  def search		
    conditions = params[:q].blank? ? nil : ForumPost.send(:sanitize_sql, ["LOWER(#{ForumPost.table_name}.body) LIKE ?", "%#{params[:q]}%"])
    @per_page = 30
    @posts = ForumPost.paginate @@query_options.merge(:conditions => conditions, :page => params[:page], :per_page => @per_page, :count => {:select => "#{ForumPost.table_name}.id"}, :order => post_order)
    @users = User.find(:all, :select => 'distinct *', :conditions => ['id in (?)', @posts.collect(&:user_id).uniq]).index_by(&:id)
    render_posts_or_xml :index
  end
  
  def monitored
    @user = User.find params[:user_id]
    options = @@query_options.merge(:conditions => ["#{Monitorship.table_name}.user_id = ? and #{ForumPost.table_name}.user_id != ? and #{Monitorship.table_name}.active = ?", params[:user_id], @user.id, true])
    options[:order]  = post_order
    options[:joins] += " inner join #{Monitorship.table_name} on #{Monitorship.table_name}.topic_id = #{Topic.table_name}.id"
    options[:page]   = @page
    options[:count]  = {:select => "#{ForumPost.table_name}.id"}
    @posts = ForumPost.paginate options
    render_posts_or_xml
  end

  def show
    if blog?
      @title = "#{@post.title}"
      @user = @post.blog.owner_type == "User" ? @post.blog.owner : @post.blog.owner.owner
      respond_to do |format|
        format.html
      end
    elsif forum?
      respond_to do |format|
        format.html { redirect_to forum_topic_path(@post.forum_id, @post.topic_id) }
        format.xml  { render :xml => @post.to_xml }
      end
    end
  end

  def new
    if forum?
      get_topic
      @title = "回覆討論串"
      @per_page = 30
      @posts = @topic.posts.paginate :page => params[:page], :per_page => @per_page
      respond_to do |format| 
        format.html { render_post_view }
        format.js
      end
    elsif blog?
      @title = "寫文章"
      @post = model.new
      respond_to do |format|
        format.html { render :action => resource_template("new") }
      end
    end
  end

  def edit
    if forum?
      @title = "編輯回覆內容"
      respond_to do |format| 
        format.html { render_post_view }
        format.js
      end
    elsif blog?
      @title = "編輯文章"
      respond_to do |format|
        format.html { render :action => resource_template("edit") }
      end
    end
  end
  
  def create
    if forum?
      @title = "回覆討論串"
      @topic = @forum.topics.find(params[:topic_id])
      if @topic.locked?
        respond_to do |format|
          format.html do
            flash[:notice] = "這個討論串已被鎖住"
            redirect_to(forum_topic_path(:forum_id => params[:forum_id], :id => params[:topic_id]))
          end
          format.xml do
            render :text => "這個討論串已被鎖住", :status => 400
          end
        end
        return
      end
      @forum = @topic.forum
      @post  = @topic.posts.build(params[:post])
      @post.user = logged_in_user
      @post.save!
      respond_to do |format|
        format.html do
          redirect_to get_post_redirect
        end
        format.xml { head :created, :location => formatted_post_url(:forum_id => params[:forum_id], :topic_id => params[:topic_id], :id => @post, :format => :xml) }
      end
    elsif blog?
      @title = "寫文章"
      @post = @blog.posts.new(params[:post])
      @post.user = logged_in_user
      @post.save!
      respond_to do |format|
        flash[:notice] = "你的文章已成功發佈"
        format.html { redirect_to blog_post_url(@blog, @post) }
      end
    end
  rescue ActiveRecord::RecordInvalid
    flash[:bad_reply] = "請寫一些內容..."
    respond_to do |format|
      if forum?
        format.html { redirect_to get_post_redirect }
      elsif blog?
        format.html { render :action => resource_template("new") }
      end
      format.xml { render :xml => @post.errors.to_xml, :status => 400 }
    end
  end

  def update
    if forum?
      @post.attributes = params[:post]
      @post.save!
      respond_to do |format|
        format.html do
          flash[:notice] = "回應內容已成功更新"
          redirect_to get_post_redirect
        end
        format.js
        format.xml { head 200 }
      end
    elsif blog?
      respond_to do |format|
        if @post.update_attributes(params[:post])
          flash[:notice] = "文章內容已成功更新"
          format.html { redirect_to blog_post_url(@blog, @post) }
        else
          format.html { render :action => resource_template("edit") }
        end
      end
    end
  end

  def destroy
    @post.destroy
    if forum?
      respond_to do |format|
        flash[:notice] = "已成功刪除一篇回應"
        format.html { redirect_to get_post_redirect_for_delete }
        format.xml { head 200 }
      end
    elsif blog?
      respond_to do |format|
        flash[:notice] = "已成功刪除文章"
        format.html { redirect_to blog_url(@blog) }
      end
    end
  end

  private

    def get_instance_vars
      if forum?
        @forum = Forum.find_by_url_key(params[:forum_id]) if params[:forum_id]
        @forum ||= Forum.find(params[:forum_id]) if params[:forum_id]
        @forum ||= Forum.find_by_url_key(params[:id]) if params[:id]
        @forum ||= Forum.find(params[:id]) if params[:id]
        @body = "forum"
      elsif blog?
        @blog = Blog.find(params[:blog_id])
        @body = "blog"
      end
    end
    
    def get_topic
      @topic = @forum.topics.find(params[:id]) if params[:id]
      @topic ||= @forum.topics.find(params[:topic_id]) if params[:topic_id]
    end
    
    def get_post
      if forum?
        @post = model.find_by_id_and_topic_id_and_forum_id(params[:id], params[:topic_id], params[:forum_id]) || raise(ActiveRecord::RecordNotFound)
      elsif blog?
        @post = model.find(params[:id]) unless params[:id].nil?
      end
    end
    
    def check_blog_mismatch
      unless @post.blog == @blog
        redirect_to index_url
        flash[:error] = "你要瀏覽的文章並不存在"
      end
    end

    def authorize_new
      if forum?
        @topic = Topic.find(params[:topic_id])
        case @forum.forumable
        when Group #Group Forum
          unless @forum.forumable.can_participate?(logged_in_user) && !@topic.locked?
            redirect_back_or_default groups_url
          end
        else #Site Forum
          unless is_logged_in? && !@topic.locked?
            redirect_back_or_default index_url
          end
        end
      elsif blog?
        if @blog.owner.class.to_s == "User"
          unless logged_in_user?(@blog.owner)
            redirect_to index_url 
            flash[:error] = "你沒有權限在這個網誌新增文章"
          end
        elsif @blog.owner.class.to_s == "Group"
          unless @blog.owner.can_participate?(logged_in_user)
            redirect_to index_url 
            flash[:error] = "你沒有權限在這個頁面新增文章"
          end
        end
      end
    end

    def authorize_edit
      if forum?
        authorized = @post.editable_by?(logged_in_user) && !@post.topic.locked?
        unless authorized
          redirect_to index_url
        end
      elsif blog?
        if @blog.owner.class.to_s == "User"
          authorized = logged_in_user?(@blog.owner) && valid_post?
          unless authorized
            redirect_to index_url
          end
        elsif @blog.owner.class.to_s == "Group"
          authorized = (@blog.owner.can_edit?(logged_in_user) || logged_in_user?(@post.user)) && valid_post?
          unless authorized
            redirect_to index_url
          end
        end
      end
    end

    def valid_post?
      @post.blog == @blog
    end

    def model
      if forum?
        ForumPost
      elsif blog?
        BlogPost
      end
    end

    def resource_template(name)
      "#{resource}_#{name}"
    end

    def resource
      if forum?
        "forum"
      elsif blog?
        "blog"
      end
    end
    
    def post_order
      "#{ForumPost.table_name}.created_at#{params[:forum_id] && params[:topic_id] ? nil : " desc"}"
    end
    
    def render_posts_or_xml(template_name = action_name)
      respond_to do |format|
        format.html { render :action => template_name }
        format.rss  { render :action => template_name, :layout => false }
        format.xml  { render :xml => @posts.to_xml }
      end
    end

    def get_post_redirect_for_delete
      topic = Topic.find(@post.topic.id) rescue nil
      if topic
        case @forum.forumable
        when Group
          group_forum_topic_path(@forum.forumable, @forum, topic)
        else
          (@post.topic.frozen? ? 
            forum_path(params[:forum_id]) :
            forum_topic_path(:forum_id => params[:forum_id], :id => params[:topic_id], :page => @page, :per_page => @per_page))
        end
      else
        case @forum.forumable
        when Group
          group_forum_path(@forum.forumable, @forum)
        else
          forum_path(@forum)
        end
      end
    end
    
    def get_post_redirect
      @per_page = 30
      case @forum.forumable
      when Group
        group_forum_topic_path(@forum.forumable, @forum, @post.topic, :anchor => @post.dom_id, :page => params[:page], :per_page => @per_page)
      else
        forum_topic_path(:forum_id => params[:forum_id], :id => params[:topic_id], :anchor => @post.dom_id, :page => params[:page], :per_page => @per_page)
      end
    end

    def render_post_view
      if forum?
        case @forum.forumable
        when Group
          @group = @forum.forumable
          render :template => 'groups/posts/' + params[:action]
        else
          render :action => resource_template(params[:action])
        end
      elsif blog?
        render :action => resource_template(params[:action])
      end
    end

    def forum?
      !params[:topic_id].nil?
    end

    def blog?
      !params[:blog_id].nil?
    end
    
end
