class GalleriesController < ApplicationController
  before_filter :login_required
  before_filter :authorize_new, :only => :new
  before_filter :gallery_owner, :only => :create
  before_filter :correct_user_required, :only => [ :edit, :update, :destroy ]
  before_filter :authorize_for_friends, :only => :show
  before_filter :authorize_for_owner, :only => :show

  def show
    @body = "galleries"
    @gallery = Gallery.find(params[:id])
    @photos = @gallery.photos.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
    @title = "#{@gallery.owner.name} 的相簿 - #{@gallery.title}"
  end
  
  def index
    @body = "galleries"
    @parent = params[:user_id].nil? ? Group.find_by_url_key(params[:group_id]) || Group.find(params[:group_id]) || Group.find(params[:id]) : User.find(params[:user_id])
    @galleries = @parent.galleries.paginate :page => params[:page]
    @title = "#{@parent.name} 的相簿"
  end
  
  def new
    @title = "建立相簿"
    @gallery = Gallery.new
  end
  
  def create
    @gallery = parent.galleries.build(params[:gallery])
    @gallery.creator = logged_in_user
    
    respond_to do |format|
      if @gallery.save
        flash[:notice] = "你已經成功新增一本相簿"
        format.html { redirect_to gallery_path(@gallery) }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  def edit
    @title = "編輯相簿"
    @gallery = Gallery.find(params[:id])
  end
  
  def update
    @gallery = Gallery.find(params[:id])
    respond_to do |format|
      if @gallery.update_attributes(params[:gallery])
        flash[:notice] = "相簿 #{@gallery.title} 的內容已經成功更新"
        format.html { redirect_to gallery_path(@gallery) }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  def destroy
    gallery = Gallery.find(params[:id])
    owner = gallery.owner
    owner_type = gallery.owner_type
    if owner.galleries.count == 1
      flash[:error] = "你不能刪除最後一個相簿"
    elsif gallery.destroy
      flash[:notice] = "相簿 #{@gallery.title} 已經成功刪除"
    else
      flash[:error] = "相簿刪除失敗。請重新嘗試"
    end

    respond_to do |format|
      if owner_type == "User"
        format.html { redirect_to user_galleries_path(logged_in_user) }
      else
        format.html { redirect_to group_galleries_path(owner) }
      end
    end
  end
 
 
  private
  
    def parent
      if user?
        User.find(params[:parent_id])
      elsif group?
        Group.find_by_url_key(params[:parent_id])
      elsif event?
        Event.find(params[:parent_id])
      end
    end
    
    def user?
      params[:parent] == "user"
    end

    def group?
      params[:parent] == "group"
    end
    
    def event?
      params[:parent] == "event"
    end
    
    def authorize_new
      if !params[:user_id].nil?
        @user = User.find(params[:user_id]) if !params[:user_id].nil?
        unless logged_in_user?(@user)
          redirect_back_or_default index_url
        end
      elsif !params[:group_id].nil?
        @group = Group.find_by_url_key(params[:group_id]) || Group.find(params[:group_id]) || Group.find(params[:id])
        unless @group.can_participate?(logged_in_user)
          redirect_back_or_default index_url
        end
      end
    end
    
    def gallery_owner
      if user?
        unless logged_in_user?(parent)
          flash[:notice] = "你無法建立這個相簿"
          redirect_to index_url
        end
      elsif group?
        unless parent.can_participate?(logged_in_user)
          flash[:notice] = "你必須是群組的成員才能建立相簿"
          redirect_to group_path(parent)
        end
      end
    end

    def correct_user_required
      @gallery = Gallery.find(params[:id])
      if @gallery.nil?
        flash[:error] = "抱歉，這個相簿並不存在"
        redirect_to user_galleries_path(logged_in_user)
      elsif @gallery.owner_type == "User"
        unless logged_in_user?(@gallery.owner)
          flash[:error] = "抱歉，你無法執行這個動作"
          redirect_to user_galleries_path(@gallery.owner)
        end
      elsif @gallery.owner_type == "Group"
        unless @gallery.owner.can_edit?(logged_in_user) || logged_in_user?(@gallery.creator)
          flash[:error] = "抱歉，你無法執行這個動作"
          redirect_to group_galleries_path(@gallery.owner)
        end
      end
    end
    
    def authorize_for_friends
      @gallery = Gallery.find(params[:id])
      if @gallery.owner_type == "User"
        if (@gallery.only_friends? &&
            !(@gallery.creator.friends.include?(logged_in_user) || logged_in_user?(@gallery.creator) || admin?))
          redirect_to index_url
        end
      elsif @gallery.owner_type == "Group"
        if (@gallery.only_friends? &&
            !(logged_in_user.own_groups.include?(@gallery.owner) || Membership.accepted?(logged_in_user, @gallery.owner) or admin?))
          redirect_to group_url(@gallery.owner)
        end
      end
    end
    
    def authorize_for_owner
      @gallery = Gallery.find(params[:id])
      if @gallery.owner_type == "User"
        if (@gallery.only_me? and
            !(logged_in_user?(@gallery.creator) or admin?))
          redirect_to index_url
        end
      elsif @gallery.owner_type == "Group"
        if (@gallery.only_me? and
            !(logged_in_user?(@gallery.creator) or logged_in_user.own_groups.include?(@gallery.owner) or admin?))
          redirect_to group_path(@gallery.owner)
        end
      end
    end
    
end
