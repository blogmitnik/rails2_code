class Groups::EventsController < ApplicationController
  include UserMethods
  include GroupMethods
  include EventMethods
  
  before_filter :get_user
  before_filter :get_group
  before_filter :get_event, :except => [:new, :create, :index, :geolocate, :showlocation]
  before_filter :login_required, :except => [:index, :show]
  before_filter :load_date, :only => [:index, :show]
  before_filter :authorization_required, :only => [:new, :edit, :create, :update, :destroy] 
  require 'geokit'
  include Geokit::Geocoders
  
  def index
    @title = "群組活動事件"
    @events = @group.events.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
    
    respond_to do |format|
      format.html do
        @user_events = EventAttendee.current_events_for(logged_in_user)
        render
      end
      format.ics do
        require 'icalendar'
        @calendar = Icalendar::Calendar.new
        @events.each do |event|
          ics_event = Icalendar::Event.new
          ics_event.start = event.start_at.strftime("%Y%m%dT%H%M%S")
          if event.end_at
            ics_event.end = event.end_at.strftime("%Y%m%dT%H%M%S")
          else
            ics_event.end = event.start
          end
          ics_event.summary = event.summary
          ics_event.description = event.description
          ics_event.location = event.location
          @calendar.add ics_event
        end
        @calendar.publish
        headers['Content-Type'] = "text/calendar; charset=UTF-8"
        render :layout => false, :text => @calendar.to_ical
      end      
    end
  end

  def show
    @title = "#{@event.title}"
    @wall_comments = @event.wall_comments.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)
    @can_participate = @group ? is_logged_in? && @group.can_participate?(logged_in_user) : false
    @has_attending = @event? is_logged_in? && @event.attendees.include?(logged_in_user) : false
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event }
      format.ics do
        ics_event = Icalendar::Event.new
        ics_event.start = @event.start_at.strftime("%Y%m%dT%H%M%S")
        if @event.end_at
          ics_event.end = @event.end_at.strftime("%Y%m%dT%H%M%S")
        else
          ics_event.end = @event.start
        end
        ics_event.summary = @event.summary
        ics_event.description = @event.description
        ics_event.location = @event.location
        @calendar.add ics_event
        @calendar.publish
        headers['Content-Type'] = "text/calendar; charset=UTF-8"
        render_without_layout :text => @calendar.to_ical
      end
    end
  end

  def new
    @title = "建立群組活動"
    @event = Event.new
    respond_to do |format|
      format.html
      format.xml  { render :xml => @event }
    end
  end
  
  def create
    @title = "建立群組活動"
    @event = @group.events.build(params[:event])
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
        flash[:notice] = "你的群組活動已成功建立"
        format.html { redirect_to(group_events_path(@group)) }
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @title = "編輯群組活動"
    respond_to do |format|
      format.html
      format.xml  { render :xml => @event }
    end
  end
  
  def update
    @title = "編輯群組活動"
    respond_to do |format|
      params[:event][:privacy] = params[:event][:privacy].to_i
      params[:event][:start_time] = params[:date][:start].to_datetime +
          params[:start][:hour].to_i.hours +
          params[:start][:minute].to_i.minutes
      params[:event][:end_time] = params[:date][:end].to_datetime +
          params[:end][:hour].to_i.hours +
          params[:end][:minute].to_i.minutes
      if @event.update_attributes(params[:event])
        flash[:notice] = "群組活動內容已成功更新"
        format.html { redirect_to(group_events_path(@group)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @event.destroy
    flash[:notice] = "群組活動 '#{@event.title}' 已成功刪除"
    respond_to do |format|
      format.html { redirect_to(group_events_path(@group)) }
      format.xml  { head :ok }
    end
  end
  
  def geolocate
    @location = MultiGeocoder.geocode(params[:address])
    if @location.success
      @coord = @location.to_a
    end
  end
  
private

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

    def permission_denied 
      flash[:error] = "你沒有權限管理編輯這個群組活動"
      respond_to do |format|
        format.html do
          redirect_to group_events_path(@group)
        end
      end
    end
  
end