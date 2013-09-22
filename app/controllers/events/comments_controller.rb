class Events::CommentsController < ApplicationController
  include UserMethods
  before_filter :get_user
  before_filter :setup
  before_filter :no_comment

  def index
    @title = "#{@event.title} 的全部留言"
    @wall_comments = @event.wall_comments.paginate(:page => params[:page], :per_page => RASTER_PER_PAGE)

    respond_to do |format|
      format.html {render}
      format.rss {render :layout=>false}
    end
  end

  protected

    def setup
      @event = Event.find(params[:event_id])
    end
    
    def no_comment
      if @event.wall_comments.empty?
        if @event.eventable_type == "Group"
          redirect_to group_event_path(@event.eventable, @event)
        else
          redirect_tp event_path(@event)
        end
      end
    end

end
