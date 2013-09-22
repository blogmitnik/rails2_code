class EventAttendeesController < ApplicationController
  skip_filter :store_location
  before_filter :login_required

  def create
    @event = Event.find(params[:event_id])
    @event_attendee = EventAttendee.new
    @event_attendee.event = @event
    @event_attendee.user = logged_in_user
    @event_attendee.save!
    @event.reload
    @has_attended = EventAttendee.find_by_user_id_and_event_id(logged_in_user, @event)
    
    respond_to do |format|
      format.html do
        redirect_back_or_default logged_in_user
      end
      format.js do
        render :update do |page|  
          page.replace_html "attend_#{@event.dom_id}", :partial => 'events/not_attending', 
          :locals => {:event => @event, :event_attendee => @event_attendee, :has_attended => @has_attended}
          page.visual_effect :highlight, "attendees_for_#{@event.dom_id}".to_sym
        end
      end
    end
  rescue ActiveRecord::RecordInvalid => ex
    format.js do
      render :update do |page|
        page << "message('" + "參與活動時出現問題，請重新載入頁面再試一次" + "');"
      end     
    end
  end

  def destroy
    @event_attendee = EventAttendee.find(params[:id])
    @event = @event_attendee.event
    @event_attendee.destroy
    
    respond_to do |format|
      format.html do
        redirect_back_or_default logged_in_user
      end
      format.js do
        render :update do |page|
          page.replace_html "attend_#{@event.dom_id}", :partial => 'events/attending', :locals => {:event => @event}
          page.visual_effect :highlight, "attendees_for_#{@event.dom_id}".to_sym
        end
      end
    end
  end  

end
