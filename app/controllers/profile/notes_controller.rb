class Profile::NotesController < ApplicationController
    before_filter :setup
    
    def index
      @title = is_me?(@user)? "你的網誌" : "#{@user.name} 的網誌"
      if @user.notes.empty?
        flash[:notice] = "#{@user.short_name} 尚未發佈任何網誌文章"
      end
      respond_to do |format|
        format.html {render}
        format.rss {render :layout=>false}
      end
    end

    def show
      @note = @user.notes.find_by_url_key(params[:id])
      @title = "#{@note.title}"
      if @note.nil?
        flash[:notice] = "無法找到這篇文章"
        redirect_to profile_notes_path(@user)
      else
        respond_to do |format|
          format.html {render}
          format.rss {render :layout=>false}
        end
      end
    end

    protected

    def setup
      @user = User.find_by_username(params[:profile_id]) || User.find(params[:profile_id])
      @notes = @user.notes.paginate(:page => @page, :per_page => RASTER_PER_PAGE)
    end

end
