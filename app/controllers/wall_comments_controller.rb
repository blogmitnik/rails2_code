class WallCommentsController < ApplicationController
  skip_filter :store_location
  before_filter :login_required
  before_filter :get_instance_vars
  before_filter :get_comment, :only => [:destroy]
  before_filter :connection_required, :except => [:show]
  before_filter :double_check_connection, :only => [:show]
  before_filter :setup

  def index
    @title = "我與 #{@user.name} 的雙向塗鴉牆"
    @user = User.find(params[:user_id])
    @wall_comments = WallComment.between_users(logged_in_user, @user).paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
    @count = @wall_comments.total_entries
    
    redirect_to logged_in_user and return if me
    respond_to do |wants|
      wants.html {render}
      wants.rss {render :layout=>false}
    end
  end
  
  def show
    @banter = User.find(params[:id])
    @wall_comments = WallComment.between_users(@banter, @user).paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
    @count = @wall_comments.total_entries
    
    @title = "#{@user.name} 與 #{@banter.name} 的雙向塗鴉牆"
    redirect_to @logged_in_user and return if self_wall
    respond_to do |wants|
      wants.html {render}
      wants.rss {render :layout=>false}
    end
  end
  
  # Used for both wall and blog comments.
  def new
    @title = "新增留言"
    @wall_comment = parent.wall_comments.new

    respond_to do |format|
      format.html { render :action => resource_template("new") }
    end
  end

  # Used for both wall and blog comments.
  def create
    @wall_comment = parent.wall_comments.new(params[:wall_comment].merge(:commenter => logged_in_user))
    
    respond_to do |wants|
      if @wall_comment.save
        wants.js do
          render :update do |page|
            page.insert_html :top, "comments_for_#{dom_id(@parent)}", :partial => 'wall_comments/comment'
            page.visual_effect :highlight, "wall_comment_#{@wall_comment.id}".to_sym
            page.visual_effect :fade, "send-error"
            page << 'jQuery("#comment-body").show();'
            page << 'jQuery("#submit-comment").show();'
            page << 'jQuery("#progress-bar").hide();'
            page << 'jQuery("#comment-body-field").val("留個言吧......");'
            page << 'jQuery("#send-comment-progress").hide();'
            page << 'tb_remove();'
          end
        end
      else
        message = "你無法發送一項空白的留言，且字數不可超過500個字。"
        wants.html do
          flash[:error] = message
          redirect_to wall_comments_url
        end
        wants.js do
          render :update do |page|
            page << 'jQuery("#progress-bar").hide();'
            page << 'jQuery("#send-comment-progress").hide();'
            page << 'jQuery("#comment-body").show();'
            page << 'jQuery("#submit-comment").show();'
            page << 'jQuery("#send-error").show();'
            page << 'tb_remove();'
          end
        end
      end
    end
  end

  def destroy
    @wall_comment = WallComment.find(params[:id])
    @wall_comment.destroy

    respond_to do |wants|
      wants.html do
        flash[:notice] = "已成功刪除一筆回應"
        redirect_back_or_default wall_comments_url
      end
      wants.js { render(:update){|page| page.visual_effect :fade, "wall_comment_#{@wall_comment.id}".to_sym}}
    end
  end

  private
  
    def get_instance_vars
      if blog?
        @blog = Blog.find(params[:blog_id])
        @post = Post.find(params[:post_id])
      elsif photo?
        @photo = Photo.find(params[:photo_id])
      elsif event?
        if params[:event_id]
          @event = Event.find(params[:event_id])
        else
          @event = Event.find(params[:id])
        end
      elsif wall?
        @user = User.find(params[:user_id])
      elsif group_wall?
        @group = Group.find(params[:group_id])
      elsif news_item?
        if params[:news_id]
          @news_item = NewsItem.find(params[:news_id])
        elsif params[:note_id]
          @news_item = NewsItem.find(params[:note_id])
        elsif params[:member_story_id]
          @news_item = NewsItem.find(params[:member_story_id])
        end
      end
    end
  
    def user
      if wall?
        @user
      elsif blog?
        @blog.owner 
      elsif photo?
        @photo.owner
      elsif event?
        @event.user
      elsif news_item?
        @news_item.newsable
      end
    end
    
    def banter
      if wall?
        @banter = User.find_by_id(params[:id])
      end
    end
    
    # Require the users to be connected.
    def connection_required
      if wall?
        unless connected_to?(user)
          respond_to do |format|
            format.js { render(:update){|page| page.alert "你無法執行這個動作"} }
            format.html { redirect_to index_url }
          end
          return
        end
      elsif group_wall?
        unless @group.can_participate?(logged_in_user)
          respond_to do |format|
            format.js { render(:update){|page| page.alert "你無法執行這個動作"} }
            format.html { redirect_to index_url }
          end
          return
        end
      elsif event?
        if @event.eventable_type == "Group"
          unless @event.eventable.can_participate?(logged_in_user) && @event.attendees.include?(logged_in_user)
            respond_to do |format|
              format.js { render(:update){|page| page.alert "你無法執行這個動作"} }
              format.html { redirect_to index_url }
            end
            return
          end
        else
          unless @event.attendees.include?(logged_in_user)
            respond_to do |format|
              format.js { render(:update){|page| page.alert "你無法執行這個動作"} }
              format.html { redirect_to index_url }
            end
            return
          end
        end
      elsif photo?
        if @photo.owner_type == "User"
          unless connected_to?(user)
            respond_to do |format|
              format.js { render(:update){|page| page.alert "你無法執行這個動作"} }
              format.html { redirect_to index_url }
            end
            return
          end
        elsif @photo.owner_type == "Group"
          unless user.can_participate?(logged_in_user)
            respond_to do |format|
              format.js { render(:update){|page| page.alert "你無法執行這個動作"} }
              format.html { redirect_to index_url }
            end
            return
          end
        end
      elsif blog?
        if @blog.owner_type == "User"
          unless connected_to?(user)
            respond_to do |format|
              format.js { render(:update){|page| page.alert "你無法執行這個動作"} }
              format.html { redirect_to index_url }
            end
            return
          end
        elsif @blog.owner_type == "Group"
          unless user.can_participate?(logged_in_user)
            respond_to do |format|
              format.js { render(:update){|page| page.alert "你無法執行這個動作"} }
              format.html { redirect_to index_url }
            end
            return
          end
        end
      elsif news_item?
        if @news_item.newsable_type == "Group"
          unless user.can_participate?(logged_in_user)
            respond_to do |format|
              format.js { render(:update){|page| page.alert "你無法執行這個動作"} }
              format.html { redirect_to index_url }
            end
            return
          end
        end
      end
    end
    
    def double_check_connection
      if wall?
        unless double_connected_to?(user, banter)
          flash[:notice] = "抱歉，你無法瀏覽這個頁面"
          redirect_to home_url
        end
      end
    end
    
    def get_comment
      @wall_comment = WallComment.find(params[:id])
  
      unless @wall_comment.can_edit?(logged_in_user) || logged_in_user?(@wall_comment.commenter) || admin?
        respond_to do |format|
          format.html do
            flash[:notice] = "你無法執行這個動作"
            redirect_back_or_default logged_in_user
          end
          format.js { render(:update){|page| page.alert "你無法執行這個動作"} }
        end
      end
    end
    
    ## The Method below is current not used.
    def authorized_to_destroy?
      @wall_comment = WallComment.find(params[:id])
      if wall?
        logged_in_user?(user) || logged_in_user?(@wall_comment.commenter)
      elsif group_wall?
        @wall_comment.commentable.can_edit?(logged_in_user) || logged_in_user?(@wall_comment.commenter)
      elsif blog?
        logged_in_user?(user) || logged_in_user?(@wall_comment.commenter)
      end
    end
    
    ## The Method below is current not used.
    def authorize_destroy
      redirect_to index_url unless authorized_to_destroy?
    end
    
    ## Handle wall and blog comments in a uniform manner.
    
    # Return the comments array for the given resource.
    def resource_comments
      if wall?
        @user.wall_comments
      elsif blog?
        @blog = Blog.find(params[:blog_id])
        @post = Post.find(params[:post_id])
      elsif photo?
        @photo.wall_comments
      elsif event?
        @event.wall_comments
      end  
    end
    
    # Return a the parent (user or photo or event) of the comment.
    def parent
      if wall?
        @user
      elsif group_wall?
        @group
      elsif blog?
        @post
      elsif photo?
        @photo
      elsif event?
        @event
      elsif news_item?
        @news_item
      end
    end
    
    # Return the template for the current resource given the name.
    # For example, on a blog resource_template("new") gives "blog_new"
    def resource_template(name)
      "#{resource}_#{name}"
    end

    # Return a string for the resource.
    def resource
      if wall?
        "wall"
      elsif group_wall?
        "group_wall"
      elsif blog?
        "blog_post"
      elsif photo?
        "photo"
      elsif event?
        "event"
      end
    end
    
    # Return the URL for the resource comments.
    def wall_comments_url
      if wall?
        profile_url(@user)
      elsif group_wall?
        group_url(@wall_comment.commentable)
      elsif blog?
        blog_post_url(@blog, @post)
      elsif photo?
        if @photo.owner_type == "User"
          user_photo_url(@photo.owner, @photo)
        elsif @photo.owner_type == "Group"
          group_photo_url(@photo.owner, @photo)
        end
      elsif event?
        event_url(@event)
      elsif news_item?
        if @news_item.newsable_type == "Group"
          group_news_url(@news_item.newsable, @news_item)
        elsif @news_item.newsable_type == "Widget"
          member_story_url(@news_item)
        elsif @news_item.newsable_type == "Site"
          news_url(@news_item)
        end
      end
    end

    def setup
      @parent = parent
      @resource_comments = resource_comments
    end

    def blog?
      !params[:blog_id].nil?
    end

    def photo?
      !params[:photo_id].nil?
    end

    def event?
      !params[:event_id].nil?
    end
    
    def news_item?
      !params[:news_id].nil? || !params[:member_story_id].nil? || !params[:note_id].nil?
    end
    
    def group_wall?
      !params[:group_id].nil? && params[:photo_id].nil? && params[:news_id].nil?
    end

    def wall?
      params[:photo_id].nil? && params[:event_id].nil? && params[:blog_id].nil? && params[:group_id].nil? && params[:news_id].nil? && params[:member_story_id].nil? && params[:note_id].nil?
    end

end
