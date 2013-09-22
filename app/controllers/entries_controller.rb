class EntriesController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  uses_tiny_mce(:options => {:theme => 'advanced', 
                            :mode => 'textareas', 
                            :browsers => %w{msie gecko webkit opera firefox},
                            :theme_advanced_toolbar_location => "top",
                            :theme_advanced_toolbar_align => "left",
                            :theme_advanced_resizing => true,
                            :theme_advanced_resize_horizontal => false,
                            :paste_auto_cleanup_on_paste => true,
                            :theme_advanced_buttons1 => %w{bold italic underline strikethrough separator justifyleft justifycenter justifyright separator bullist numlist forecolor backcolor separator link unlink image undo redo code},
                            :theme_advanced_buttons2 => [],
                            :theme_advanced_buttons3 => [],
                            :editor_selector => 'mceEditor',
                            :plugins => %w{contextmenu paste}},
                            :only => [:new, :edit, :create])
  
  def index
    @user = User.find(params[:user_id])
    @entry_pages = Paginator.new(self, @user.entries_count, 10, params[:page])
    @entries = @user.entries.find(:all, :order => 'created_at DESC',
                                  :limit => @entry_pages.items_per_page,
                                  :offset => @entry_pages.current.offset)
    @title = "#{@user.name} 的美食評論"
    
    @usertemplate = @user.usertemplates.find_by_name('blog_index')
    if @usertemplate and @usertemplate.body.any?
      @page = Liquid::Template.parse(@usertemplate.body)
      render :text => @page.render({'user' => @user, 'entries' => @entries}, [TextFilters])
    end
  end

  def show
    @user = User.find(params[:user_id], :include => :usertemplates)
    @entry = Entry.find_by_id_and_user_id(params[:id], 
                                          params[:user_id], 
                                          :include => [:user, [:comments => :user]])
    @entry_pages = Paginator.new(self, @user.entries_count, 10, params[:page])
    @entries = @user.entries.find(:all, :order => 'created_at DESC',
                                  :limit => @entry_pages.items_per_page,
                                  :offset => @entry_pages.current.offset)
    @title = "#{@user.name} 的美食評論 - #{@entry.title}"
    if @entry.show_geo && (@entry.geo_lat && @entry.geo_long)
      @map = GMap.new("map_div_id")
      @map.control_init(:map_type => true, :scale => true, :small_map => true)
      @map.center_zoom_init([@entry.geo_lat, @entry.geo_long], 10)
      marker = GMarker.new([@entry.geo_lat, @entry.geo_long],
      :title => @entry.title,
      :info_window => @entry.body)
      @map.overlay_init(marker)
    end
                                          
    @usertemplate = @user.usertemplates.find_by_name('blog_entry')
    if @usertemplate and @usertemplate.body.any?
      @page = Liquid::Template.parse(@usertemplate.body)
      render :text => @page.render({'user' => @user, 'entry' => @entry, 'comments' => @entry.comments}, [TextFilters])
    end
  end

  def new
    @entry = Entry.new
    @title = "分享美食評論"
    @map = GMap.new("map_div_id")
    @map.control_init(:map_type => true, :large_map => true, :scale => true, :overview_map => true)
    @map.center_zoom_init([25,0], 1)
    @map.record_init @map.on_click("function (overlay, point) { updateLocation1(point); }")
  end

  def edit
    @entry = @logged_in_user.entries.find(params[:id])
    @title = "編輯文章內容"
    
    @map = GMap.new("map_div_id")
    @map.control_init(:map_type => true, :large_map => true, :scale => true, :overview_map => true)
    if @entry.geo_lat && @entry.geo_long
      @map.center_zoom_init([@entry.geo_lat, @entry.geo_long], 10)
      
      marker = GMarker.new([@entry.geo_lat, @entry.geo_long], 
        :title => @entry.title, :info_window => @entry.body)
      @map.overlay_init(marker)
    else
      @map.center_zoom_init([25,0], 1)
    end
    
    @map.record_init @map.on_click("function (overlay, point) { updateLocation1(point); }")
      
    rescue ActiveRecord::RecordNotFound
    flash[:notice] = "只有這篇文章的擁有者才能執行這個動作"
    redirect_back_or_default(user_entry_path(:user_id => params[:user_id], :id => params[:id]))
  end

  def create
    @title = "分享美食評論"
    @entry = Entry.new(params[:entry])
    if @entry.duplicate?
      flash[:notice] = '你已經寫過同樣內容的文章'
      redirect_to user_entries_path(:user_id => logged_in_user)
    elsif logged_in_user.entries << @entry
      flash[:notice] = '你的文章已經成功發佈'
      redirect_to user_entries_path(:user_id => logged_in_user)
    else
      render :action => 'new'
    end
  end

  def update
    @entry = @logged_in_user.entries.find(params[:id])

    if @entry.update_attributes(params[:entry])
      flash[:notice] = '你的美食評論文章已經成功更新'
      redirect_to user_entries_path(:user_id => logged_in_user)
    else
      redirect_to user_entry_path(:user_id => logged_in_user, :id => @entry)
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = "只有這篇文章的擁有者才能執行這個動作"
    redirect_back_or_default(user_entry_path(:user_id => params[:user_id], :id => params[:id]))
  end

  def destroy
    @entry = @logged_in_user.entries.find(params[:id])
    @entry.destroy

    redirect_to user_entries_path(:user_id => logged_in_user)
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = "只有這篇文章的擁有者才能執行這個動作"
    redirect_back_or_default(user_entry_path(:user_id => params[:user_id], :id => params[:id]))
  end
end
