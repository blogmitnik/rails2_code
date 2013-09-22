class UserPhotosController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :mix]
  before_filter :correct_user_required,
                :only => [ :edit, :update, :destroy ]
  before_filter :correct_manager_required, :only => :set_avatar
  before_filter :correct_creator_required, :only => :set_primary
  before_filter :correct_gallery_requried, :only => [:new, :create]
  require 'yahoo_search'
  
  def index
    @title = "管理相片"
    @user = User.find(params[:user_id])
    @per_page = 50
    @photos = @user.photos.paginate(:all, :page => params[:page], :per_page => @per_page)
    if logged_in_user?(@user)
      respond_to do |format|
        format.html # index.html.erb
        format.xml { render :xml => @photos.to_xml }
      end
    else
      redirect_to user_galleries_path(@user)
    end
  end
  
  def show
    @parent = params[:user_id].nil? ? Group.find_by_url_key(params[:group_id]) || Group.find(params[:group_id]) || Group.find(params[:id]) : User.find(params[:user_id])
    @photo = Photo.find(params[:id])
    @user = params[:user_id].nil? ? @photo.owner.owner : @photo.owner
    @wall_comments = @photo.wall_comments.paginate(:page => params[:page], 
                                                   :per_page => RASTER_PER_PAGE)
    @title = "#{@photo.owner.name} 的相片 - #{@photo.gallery.title}"
    
    if @photo.show_geo && (@photo.geo_lat && @photo.geo_long)
      @map = GMap.new("map_div_id")
      @map.control_init(:map_type => true, :scale => true, :small_map => true, :overview_map => true)
      @map.center_zoom_init([@photo.geo_lat, @photo.geo_long], 10)
      marker = GMarker.new([@photo.geo_lat, @photo.geo_long], 
                            :title => @photo.title, 
                            :info_window => %(<div class="profile-image left"><img src="#{@photo.public_filename('small')}"></div><div>#{@photo.body}</div>))
      @map.overlay_init(marker)
    end
    
      respond_to do |format|
        format.html # show.html.erb
        format.xml { render :xml => @photo.to_xml }
      end
  end
  
  def new
    @title = "上傳相片"
    @photo = Photo.new
    @gallery = Gallery.find(params[:gallery_id])
    
    @map = GMap.new("map_div_id")
    @map.control_init(:map_type => true, :large_map => true, :scale => true)
    @map.center_zoom_init([25,0], 1)
    @map.record_init @map.on_click(
      "function (overlay, point) { updateLocation(point); }")
      
    respond_to do |format|
      format.html
    end
  end
  
  def edit
    @title = "編輯圖片"
    @display_photo = @photo
    
    @map = GMap.new("map_div_id")
    @map.control_init(:map_type => true, :large_map => true, :scale => true, :overview_map => true)
    if @photo.geo_lat && @photo.geo_long
      @map.center_zoom_init([@photo.geo_lat, @photo.geo_long], 10)
      
      marker = GMarker.new([@photo.geo_lat, @photo.geo_long], 
                            :title => @photo.title, 
                            :info_window => %(<div class="profile-image"><img src="#{@photo.public_filename('small')}"></div>#{@photo.title}))
      @map.overlay_init(marker)
    else
      @map.center_zoom_init([25,0], 1)
    end
    
    @map.record_init @map.on_click(
      "function (overlay, point) { updateLocation(point); }")
    
    rescue ActiveRecord::RecordNotFound
    redirect_to :action => 'index'
    
    respond_to do |format|
      format.html
    end
  end
  
  def create
    if params[:photo].nil?
      # This is mainly to prevent exceptions on iPhones.
      flash[:error] = "你目前使用的瀏覽器並不支援檔案上傳"
      redirect_to gallery_path(Gallery.find(params[:gallery_id])) and return
    end
    
    photo_data = params[:photo].merge(:owner_id => @gallery.owner.id,
                                      :owner_type => @gallery.owner_type)
    @photo = @gallery.photos.build(photo_data)
    @photo.creator = logged_in_user
    
    respond_to do |format|
      if @photo.save
        flash[:notice] = "相片已成功被建立"
        format.html { redirect_to @photo.gallery }
        format.xml { head :created, :location => user_photo_path(:user_id => @photo.user_id, :id => @photo) }
      else
        format.html { render :action => 'new' }
        format.xml { render :xml => @photo.errors.to_xml }
      end
    end
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end
  
  def update
    @photo = Photo.find(params[:id])
    
    respond_to do |format|
      if @photo.update_attributes(params[:photo])
        flash[:notice] = '相片內容已成功更新'
        format.html { redirect_to(gallery_path(@photo.gallery)) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @photo.errors.to_xml }
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to :action => 'index'
  end
  
  def destroy
    @gallery = @photo.gallery
    @photo.destroy
    flash[:notice] = "相片已成功刪除"
    
    respond_to do |format|
      format.html { redirect_to gallery_path(@gallery) }
      format.xml { head :ok }
    end
    
    rescue ActiveRecord::RecordNotFound
    redirect_to :action => 'index'
  end
  
  def set_primary
    @photo = Photo.find(params[:id])
    if @photo.nil? or @photo.primary?
      if @photo.owner_type == "User"
        redirect_to user_galleries_path(logged_in_user) and return
      elsif @photo.owner_type == "Group"
        redirect_to group_galleries_path(@photo.owner) and return
      end
    end
    # This should only have one entry, but be paranoid.
    @old_primary = @photo.gallery.photos.select(&:primary?)
    return unless request.put?
    
    respond_to do |format|
      if @photo.update_attributes(:primary => true)
        @old_primary.each { |p| p.update_attributes!(:primary => false) }
        if @photo.owner_type == "User"
          format.html { redirect_to(user_galleries_path(logged_in_user)) }
          flash[:notice] = "已成功設定相簿 #{@photo.gallery.title} 的封面照片"
        elsif @photo.owner_type == "Group"
          format.html { redirect_to(group_galleries_path(@photo.owner)) }
          flash[:notice] = "已成功設定相簿 #{@photo.gallery.title} 的封面照片"
        end

      else    
        format.html do
          flash[:error] = "抱歉，你上傳的這張相片是不合法的"
          redirect_to index_url
        end
      end
    end
  end
  
  def set_avatar
    @photo = Photo.find(params[:id])
    if @photo.nil? or @photo.avatar?
      if @photo.owner_type == "User"
        redirect_to logged_in_user and return
      else
        redirect_to @photo.owner and return
      end
    end
    # This should only have one entry, but be paranoid.
    @old_primary = @photo.owner.photos.select(&:avatar?)
    return unless request.put?
    
    respond_to do |format|
      if @photo.update_attributes!(:avatar => true)
        @old_primary.each { |p| p.update_attributes!(:avatar => false) }
        if @photo.owner_type == "User"
          flash[:notice] = "已成功設定個人檔案相片"
          format.html { redirect_to(profile_path(@photo.owner)) }
        elsif @photo.owner_type == "Group"
          flash[:notice] = "已成功設定群組檔案相片"
          format.html { redirect_to(group_path(@photo.owner)) }
        end
      else    
        format.html do
          flash[:error] = "抱歉，你上傳的這張相片是不合法的"
          redirect_to index_url
        end
      end
    end
  end
  
  def add_tag
    @photo = @logged_in_user.photos.find(params[:id])
    # changed to reflect latest version of acts_as_taggable_on_steroids
    @photo.tag_list.names << params[:tag][:name]
    if @photo.save
      @new_tag = @photo.reload.tags.find_by_name params[:tag][:name]
    else
      render :nothing => true
    end
  end
  
  def remove_tag
    @photo = @logged_in_user.photos.find(params[:id])
    @tag_to_delete = @photo.tags.find(params[:tag_id])
    if @tag_to_delete
      @photo.tags.delete(@tag_to_delete)
    else
      render :nothing => true
    end
  end
  
  def mix
    s = 'error'
    begin
      @associates = Yahoo::ImageSearch.new(Yahoo::APPID, 5).search(params[:title], params[:count].to_i)
      render :partial => 'others'
      return
    rescue
      s = $!.message
    end
    render :text => s
  end
  
  private
  
    def correct_manager_required
      @photo = Photo.find(params[:id])
      if @photo.nil?
        flash[:error] = "這張相片並不存在！"
        redirect_to index_url
      elsif @photo.owner_type == "User"
        unless logged_in_user?(@photo.owner)
          redirect_to profile_path(@photo.owner)
        end
      elsif @photo.owner_type == "Group"
        unless @photo.owner.can_edit?(logged_in_user)
          redirect_to group_path(@photo.owner)
        end
      end
    end
    
    def correct_user_required
      @photo = Photo.find(params[:id])
      if @photo.nil?
        flash[:error] = "這張相片並不存在！"
        redirect_to index_url
      elsif @photo.owner_type == "User"
        unless logged_in_user?(@photo.owner)
          redirect_to user_photo_path(@photo.owner, @photo)
        end
      elsif @photo.owner_type == "Group"
        unless @photo.owner.can_edit?(logged_in_user) || logged_in_user?(@photo.creator)
          redirect_to group_photo_path(@photo.owner, @photo)
        end
      end
    end
    
    def correct_creator_required
      @photo = Photo.find(params[:id])
      if @photo.nil?
        flash[:error] = "這張相片並不存在！"
        redirect_to index_url
      elsif @photo.owner_type == "User"
        unless logged_in_user?(@photo.owner)
          redirect_to user_photo_path(@photo.owner, @photo)
        end
      elsif @photo.owner_type == "Group"
        unless logged_in_user?(@photo.creator) && logged_in_user?(@photo.gallery.creator)
          redirect_to group_photo_path(@photo.owner, @photo)
        end
      end
    end
    
    def correct_gallery_requried
      if params[:gallery_id].nil?
        flash[:error] = "你必須選擇一個相簿來上傳相片"
        redirect_to index_url
      else
        @gallery = Gallery.find(params[:gallery_id])
        if @gallery.owner_type == "User"
          unless logged_in_user?(@gallery.owner)
            flash[:error] = "抱歉，你無法上傳相片到這個相簿"
            redirect_to user_galleries_path(@gallery.owner)
          end
        elsif @gallery.owner_type == "Group"
          unless @gallery.owner.can_participate?(logged_in_user)
            flash[:error] = "抱歉，你無法上傳相片到這個相簿"
            redirect_to group_galleries_path(@gallery.owner)
          end
        end
      end
    end
    
  
end