class GroupsController < ApplicationController
  include GroupsHelper
  include GroupMethods
  before_filter :login_required, :except => [:index, :show]
  before_filter :setup, :except => [:index, :new, :create]
  before_filter :group_creator => [:edit, :update, :destroy]
  before_filter :group_owner, :only => [:new_photo, :save_photo, :delete_photo]
  
  def index
    @title = "群組"
    @visibility_threshold = admin? ? 3 : 2
    @user = logged_in_user
    if params[:alpha_index]
      @alpha_index = params[:alpha_index]
      @groups = Group.find(:all, :conditions => ["mode < ? AND name LIKE ?", @visibility_threshold, @alpha_index + '%'], :order => 'name').paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
    else
      @groups = Group.find(:all, :conditions => ["mode < ?", @visibility_threshold], :order => 'name').paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
    end
    @my_groups = is_logged_in? ? logged_in_user.groups : []
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @groups }
    end
  end

  def show
    @parent = @group
    @title = "#{@group.name}"
    num_friends = User::MAX_DEFAULT_FRIENDS
    @google_docs = @group.public_google_docs
    @shared_uploads = @group.shared_uploads.find(:all, :limit => 5, :order => 'created_at DESC')
    @members = @group.users
    @some_members = @members[0...num_friends]
    @managers = @group.manager
    @some_managers = @managers[0...num_friends]
    @blog = @group.blog
    @posts = @group.blog.posts.paginate(:page => params[:page])
    @galleries = @group.galleries.paginate(:page => params[:page])
    @news = @group.news_items.find(:all, :limit => 3, :order => 'created_at DESC')
    @forum = @group.forums.first
    @topics = @forum.topics.find(:all, :limit => 3, :order => 'replied_at DESC')
    @user = logged_in_user
    group_redirect_if_not_public
  end

  def new
    @title = "建立群組"
    @group = Group.new
    @groups = Group.find(:all, :conditions => 'mode < 2', :limit => 16, :order => 'created_at desc')
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @group }
    end
  end

  def edit
    @title = "編輯群組頁面"
  end

  def create
    @title = "編輯群組內容"
    @group = Group.new(params[:group])
    @group.owner = logged_in_user

    respond_to do |format|
      if @group.save
        flash[:notice] = "你的群組已經成功建立"
        format.html { redirect_to(group_path(@group)) }
        format.xml  { render :xml => @group, :status => :created, :location => @group }
      else
        flash[:notice] = "建立群組頁面時出現問題，請重新嘗試一次"
        format.html { render :action => "new" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @group.update_attributes(params[:group])
        flash[:notice] = "群組頁面內容已經成功更新"
        format.html { redirect_to(group_path(@group)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @group.delete!
    respond_to do |format|
      flash[:notice] = "你已成功刪除#{@group.nanme}群組"
      format.html { redirect_to(groups_path) }
      format.xml  { head :ok }
    end
  end
  
  def update_memberships_in
    if manager? || logged_in_user.own_groups.include?(@group)
      params[:group_member_role].each do |user_id, role|
        membership = @group.memberships.find_by_user_id(user_id)
        membership.role = role
        membership.save!
      end
      flash[:notice] = "已成功更新使用者權限"
    end
    redirect_to group_path(@group)
  end
  
  def invite
    @title = "邀請人們加入 #{@group.name}"
    @friends = friends_to_invite

    respond_to do |format|
      if (@group.can_edit?(logged_in_user) and @group.hidden?) or (@group.is_member?(logged_in_user) and !@group.hidden?)
        if @friends.length == 0
          flash[:error] = "你還沒有任何朋友，或你已經邀請過所有的朋友。"
          format.html { redirect_to(group_path(@group)) }
        end
        format.html
      else
        format.html { redirect_to(group_path(@group)) }
      end
    end
  end

  def invite_them
    @title = "邀請人們加入 #{@group.name}"
    @subject = params[:subject] || "#{logged_in_user.name} 邀請你加入 #{@group.name} 群組"
    @message_body = params[:message_body] || "嗨，邀請你一起參與我在 #{app_name} 上的群組 #{@group.name}"
    invitations = params[:checkbox].collect{|x| x if  x[1]=="1" }.compact
    invitations.each do |invitation|
      if Membership.find_all_by_group_id(@group, :conditions => ['user_id = ?',invitation[0].to_i]).empty?
        invited_user = User.find(invitation[0].to_i)
        Membership.invite(User.find(invitation[0].to_i),@group)
        UserNotifier.deliver_group_invite(logged_in_user, @group, invited_user.email, invited_user.name, @subject, @message_body)
      end
    end
    respond_to do |format|
      flash[:notice] = "你已經成功邀請朋友加入 #{@group.name}"
      format.html { redirect_to(group_path(@group)) }
    end
  end
  
  def members
    @title = "群組成員"
    @members = @group.users.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
    @pending = @group.pending_request.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)

    respond_to do |format|
      format.html do
        if @group && (!@group.hidden? || @group.is_member?(logged_in_user) || admin? ||
          @group.owner?(logged_in_user) || @group.has_invited?(logged_in_user))
          if manager?
            render :template => 'groups/admin/index'
          else
            render
          end
        else
          format.html { redirect_to(groups_path) }
        end
      end
      format.rss { render :layout => false }
    end
  end
  
  def photos
    @photos = @group.photos
    respond_to do |format|
      format.html
    end
  end
  
  def new_photo
    @title = "上傳相片"
    @photo = Photo.new

    respond_to do |format|
      format.html
    end
  end
  
  def save_photo
    if params[:photo].nil?
      # This is mainly to prevent exceptions on iPhones.
      flash[:error] = "你目前使用的瀏覽器並不支援檔案上傳"
      redirect_to(edit_group_path(@group)) and return
    end
    if params[:commit] == "取消"
      flash[:notice] = "你取消了圖片上傳"
      redirect_to(edit_group_path(@group)) and return
    end
    
    group_data = { :group => @group,
                   :primary => @group.photos.empty? }
    @photo = Photo.new(params[:photo].merge(group_data))
    
    respond_to do |format|
      if @photo.save
        flash[:success] = "你的相片已經成功建立。你現在可以為相片建立標籤"
        if group.owner == logged_in_user
          format.html { redirect_to(edit_group_path(group)) }
        else
          format.html { redirect_to(group_path(group)) }
        end
      else
        format.html { render :action => "new_photo" }
      end
    end
  end
  
  def delete_photo
    @photo = Photo.find(params[:photo_id])
    @photo.destroy
    flash[:success] = "你已經將圖片從群組 '#{@group.name}' 中移除"
    respond_to do |format|
      format.html { redirect_to(edit_group_path(@group)) }
    end
  end
  
  private
  
  def setup
    @group = Group.find_by_url_key(params[:id]) rescue nil
    @group = Group.find(params[:id]) rescue nil if @group.nil?
    @can_participate = @group ? is_logged_in? && @group.can_participate?(logged_in_user) : false
  end
  
  def friends_to_invite
    logged_in_user.friends
  end
  
  def group_creator
    redirect_to index_url unless logged_in_user.own_groups.include?(@group)
  end
  
  def group_owner
    redirect_to index_url unless @group.can_participate?(logged_in_user)
  end
  
  def group_redirect_if_not_public
    respond_to do |format|
      if @group && (!@group.hidden? || @group.is_member?(logged_in_user) || admin? ||
          @group.owner?(logged_in_user) || @group.has_invited?(logged_in_user))
        format.html # show.html.erb
        format.xml  { render :xml => @group }
      else
        message = "無法找到這個群組"
        format.html do 
          flash[:notice] = message
          redirect_back_or_default groups_path
        end
        format.xml do
          render :xml => '<message>' + message + '</message>'
        end
      end
    end
  end
  
end
