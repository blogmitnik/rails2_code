class EventsController < ApplicationController
  include UserMethods
  include EventMethods
  
  before_filter :login_required
  before_filter :get_event, :except => [:new, :create, :index, :geolocate, :showlocation]
  before_filter :load_date, :only => [:index, :show]
  before_filter :authorize_show, :only => :show
  before_filter :authorize_change, :only => [:edit, :update]
  before_filter :authorize_destroy, :only => :destroy
  require 'geokit'
  include Geokit::Geocoders
  
  def index
    @title = "事件活動"
    @month_events = Event.monthly_events(@date).user_events(logged_in_user).paginate(:order => 'created_at DESC', :page => params[:page], 
                                                                                     :per_page => RASTER_PER_PAGE)
    @user_events = EventAttendee.current_events_for(logged_in_user)
    
    unless filter_by_day?
      @events = @month_events
    else
      @events = Event.daily_events(@date).user_events(logged_in_user).paginate(:page => params[:page], 
                                                                               :per_page => RASTER_PER_PAGE)
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @events }
    end
  end

  def show
    @title = "活動項目 - #{@event.title}"
    @month_events = Event.monthly_events(@date).user_events(logged_in_user)
    @attendees = @event.attendees.paginate(:page => params[:page], 
                                           :per_page => RASTER_PER_PAGE)
    @wall_comments = @event.wall_comments.paginate(:page => params[:page], 
                                                  :per_page => RASTER_PER_PAGE)
    @has_attending = @event? is_logged_in? && @event.attendees.include?(logged_in_user) : false

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event }
    end
  end

  def new
    @title = "新增事件活動"
    @event = Event.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event }
    end
  end

  def edit
    @title = "編輯事件活動"
  end

  def create
    @event = Event.new(params[:event])
    @event.user = logged_in_user
    @event.privacy = params[:event][:privacy].to_i
    @event.start_time = params[:date][:start].to_time +
        params[:start][:hour].to_i.hours +
        params[:start][:minute].to_i.minutes
    @event.end_time = params[:date][:end].to_time +
        params[:end][:hour].to_i.hours +
        params[:end][:minute].to_i.minutes

    respond_to do |format|
      if @event.save
        flash[:notice] = "你的活動項目已經成功建立"
        format.html { redirect_to(@event) }
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      params[:event][:privacy] = params[:event][:privacy].to_i
      params[:event][:start_time] = params[:date][:start].to_datetime +
          params[:start][:hour].to_i.hours +
          params[:start][:minute].to_i.minutes
      params[:event][:end_time] = params[:date][:end].to_datetime +
          params[:end][:hour].to_i.hours +
          params[:end][:minute].to_i.minutes
      if @event.update_attributes(params[:event])
        flash[:notice] = "你的活動項目內容已經成功更新"
        format.html { redirect_to(@event) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @event.destroy

    respond_to do |format|
      format.html { redirect_to(events_url) }
      format.xml  { head :ok }
    end
  end

  def attend
    if @event.attend(logged_in_user)
      flash[:notice] = "你現在已經參與這個事件活動了"
      redirect_to event_path(@event)
    else
      flash[:error] = "你已經參與這個事件活動了"
      redirect_to event_path(@event)
    end
  end

  def unattend
    if @event.unattend(logged_in_user)
      flash[:notice] = "你已經不再參與這個事件活動"
      redirect_to event_path(@event)
    else
      flash[:error] = "你已經不再參與這個事件活動"
      redirect_to event_path(@event)
    end
  end
  
  def delete_icon
    respond_to do |format|
      event = Event.find(params[:id])
      event.update_attribute :icon, nil
      format.js { render(:update){|page| page.visual_effect :fade, 'avatar_edit'}}
    end      
  end
  
  def geolocate
    @location = MultiGeocoder.geocode(params[:address])
    if @location.success
      @coord = @location.to_a
    end
  end

  private
    
    def in_progress
      flash[:notice] = "此功能尚有一些部份可能需要調整..."
    end
  
    def authorize_show
      if (@event.only_friends? and
          not (@event.user.friends.include?(logged_in_user) or
               logged_in_user?(@event.user) or admin?))
        redirect_to index_url 
      end
    end
  
    def authorize_change
      redirect_to index_url unless logged_in_user?(@event.user)
    end

    def authorize_destroy
      can_destroy = logged_in_user?(@event.user) || logged_in_user.has_role?('Administrator')
      redirect_to index_url unless can_destroy
    end

    def load_date
      if @event
        @date = @event.start_time
      else
        now = Time.now
        year = (params[:year] || now.year).to_i
        month = (params[:month] || now.month).to_i
        day = (params[:day] || now.mday).to_i
        @date = DateTime.new(year,month,day)
      end
    rescue ArgumentError
      @date = Time.now
    end

    def filter_by_day?
      !params[:day].nil?
    end

end