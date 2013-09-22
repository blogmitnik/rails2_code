class Groups::Events::PhotosController < ApplicationController
  include GroupMethods
  include UserMethods
  
  before_filter :login_required, :only => [:destroy, :create]
  before_filter :get_group
  before_filter :get_user
  before_filter :setup
  before_filter :authorization_required, :only => [:destroy] 
  before_filter :membership_required, :only => [:create]
  before_filter :has_attending, :only => [:create]

  def index
    @title = "來自#{@event.title}的相片"
    @per_page = 50
    @photos = @event.photos.paginate(:page => params[:page], :per_page => @per_page)

    respond_to do |format|
      format.html { render }
      format.rss { render :layout => false }
    end
  end

  def show
    redirect_to group_event_photos_path(@group, @event)
  end

  def create
    params[:photo][:creator_id] = logged_in_user.id
    @photo = @event.photos.build params[:photo]

    respond_to do |format|
      if @photo.save
        format.html do
          flash[:notice] = "活動相片已成功建立"
          redirect_to group_event_photos_path(@group, @event)
        end
      else
        format.html do
          flash.now[:error] = "上傳失敗，請重新嘗試一次"
          render :action => :index
        end
      end
    end
  end

  def destroy
    Photo[params[:id]].destroy
    respond_to do |format|
      format.html do
        flash[:notice] = "活動相片已成功刪除"
        redirect_to group_event_photos_path(@group, @event)
      end
    end
  end


  private

  def setup
    @photo = Photo.new
    @event = Event.find(params[:event_id])
    @can_participate = @group ? is_logged_in? && @group.can_participate?(logged_in_user) : false
    @has_attending = @event? is_logged_in? && @event.attendees.include?(logged_in_user) : false
  end
  
  def has_attending
    unless @has_attending
      flash[:notice] = "你必須先參與這個活動才能上傳相片"
      redirect_to group_event_photos_path(@group, @event)
    end
  end

  def permission_denied 
    flash[:error] = "你沒有權限刪除這張相片"     
    respond_to do |format|
      format.html do
        redirect_to group_event_photos_path(@group, @event)
      end
    end
  end

end