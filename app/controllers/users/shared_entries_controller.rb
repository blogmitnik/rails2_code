class Users::SharedEntriesController < ApplicationController
  include UserMethods
  
  before_filter :login_required, :except => [:show]
  before_filter :get_user 
  before_filter :authorization_required, :only => [:edit, :create, :new]
  before_filter :setup, :only => [:show, :edit, :destroy]

  def show
    @title = "#{@entry.title}"
    @can_edit = (@user.id == logged_in_user.id)

    if !@entry.google_doc
      redirect_to @entry.permalink
      return
    end

    if @entry.is_presentation
      render :template => 'users/shared_entries/presentation'
      return
    end

    @html = @entry.html
    if @html == nil
      redirect_to edit_user_entry_path(@user, @entry)
      return
    end

    render :layout => 'google_docs'
  end

  def new
    @title = "轉貼連結"
    @group_id = (params[:group_id] || -1).to_i    
    @entry = Entry.new
    @entry.permalink = params[:u]
    @entry.body = params[:c] || ''
    @entry.body += video_include_text(@entry.permalink)
    @entry.title = params[:t]
    @entry.title = @entry.title[0,@entry.title.rindex(' -')] if @entry.title && @entry.title.index(' - Google Doc')
    @groups = logged_in_user.groups + logged_in_user.own_groups
    @friends = logged_in_user.friends + logged_in_user.pending_friends
  end

  def create
    @title = "轉貼連結"
    @entry = logged_in_user.entries.build(params[:entry])
    respond_to do |format|
      if @entry.save
        @friend_ids = (params[:friend_ids] || Array.new)
        @friend_ids.store(logged_in_user.id,"1") if params[:dashboard] == 'on'
        @entry.share_with_friends(logged_in_user, @friend_ids, params[:share_to_edit] == 'on', params[:profile] == 'on') if !@friend_ids.empty?

        @group_ids = params[:group_ids] || Hash.new
        @entry.share_with_groups(logged_in_user, @group_ids) if !@group_ids.empty?

        format.html do
          flash[:notice] = %(轉貼完成！想更輕鬆的分享網頁嗎？你可以利用<a href="#{protected_page_path('get_bookmarklet')}">分享書籤集</a>哦。)
          if params[:bookmarklet] == true
            redirect_to @entry.permalink
          else
            redirect_to index_url
          end
        end
      else
        format.html do
          flash.now[:error] = "對不起，你輸入了一個無效的URL。"
          render :action => :new
        end
      end
    end
  end

  def edit
    @title = "編輯文件內容"
    if !@entry.google_doc || request.user_agent.downcase.index("msie") || @entry.is_presentation
      redirect_to @entry.permalink
      return
    end
    render
  end

  def destroy
    if @shared_entry.destination_id == logged_in_user.id
      @shared_entry.destroy 
      respond_to do |format|
        format.html do
          flash[:notice] = "轉貼連結已成功刪除。"
          redirect_to home_path
        end
        format.js { render(:update){|page| page.visual_effect :fade, "shared_entry_#{params[:id]}".to_sym}}
      end
    end
  end

  def setup
    @shared_entry = SharedEntry.find(params[:id], :include => 'entry')
    @entry = @shared_entry.entry
  end

  private

  def video_include_text url
    return '' if url == nil || url.empty?
    if url.match(/video\.google\.com/)
      return "[googlevideo: #{url}]"
    elsif url.match(/youtube\.com/)
      return "[youtube: #{url}]"
    end
    return ''
  end    
end
