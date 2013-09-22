class ForumsController < ApplicationController
  include ForumMethods
  before_filter :login_required, :except => [:index, :show]
  before_filter :find_forum, :only => [:show, :update, :destroy]
  before_filter :check_moderator_role, :except => [:index, :show]
  
  cache_sweeper :posts_sweeper, :only => [:create, :update, :destroy]

  def index
    @title = "討論區"
    @forums = Forum.site_forums.by_position    
    # reset the page of each forum we have visited when we go back to index
    session[:forum_page] = nil
    if @forums.length == 1
      redirect_to forum_url(@forums.first) and return
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @forums }
    end
  end

  def show
    @title = "#{@forum.name}"
    @can_participate = is_logged_in? ? true : false
    respond_to do |format|
      format.html do
        setup_show_forum
      end
      format.xml { render :xml => @forum }
      format.atom
    end
  end

  def new
    @title = "建立討論區"
    @forum = Forum.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @forum }
    end
  end

  def create
    @title = "建立討論區"
    @forum = Forum.new(params[:forum])
    @forum.forumable_type = "Site"
    respond_to do |format|
      if @forum.save
        format.html { redirect_to forum_path(@forum) }
        format.xml  { head :created, :location => formatted_forum_url(@forum, :xml) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @forum.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def edit
    @title = "編輯討論區"
    render
  end
  
  def update
    @title = "編輯討論區"
    respond_to do |format|
      if @forum.update_attributes!(params[:forum])
        format.html { redirect_to @forum }
        format.xml  { head 200 }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @forum.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @forum.destroy
    respond_to do |format|
      format.html { redirect_to forums_path }
      format.xml  { head 200 }
    end
  end
  
  private
  
  def setup
    @body = "forum"
  end
  
end
