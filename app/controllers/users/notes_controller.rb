class Users::NotesController < ApplicationController
  #web_service_api BloggerAPI
  include NewsItemMethods
  include UserMethods
  
  before_filter :login_required
  before_filter :get_user
  before_filter :authorization_required
  before_filter :get_news_item, :only => [:edit, :update, :destroy]

  uses_tiny_mce(:options => GlobalConfig.news_mce_options,
                :only => [:new, :create, :edit, :update])
                
  def index
    @title= "我的網誌文章"
    @notes = @user.notes.paginate(:page => params[:page], :per_page => 30)
    respond_to do |format|
      format.html {render}
      format.rss {render :layout=>false}
      format.js do
        root_part = user_notes_path(@user) + '/' 
        render :json => autocomplete_urls_json(@notes, root_part) 
      end
    end
  end

  def new
    @title = "寫文章"
    @news_item = @user.notes.build
    render
  end

  def create
    @title = "寫文章"
    @news_item = logged_in_user.notes.build(params[:news_item])
    @news_item.creator = logged_in_user

    respond_to do |format|
      if @news_item.save
        format.html do
          flash[:notice] = "你的網誌文章已發表。"
          redirect_to user_notes_path(@user)
        end
      else
        format.html do
          flash.now[:error] = "發表文章時出錯，請重新嘗試。"
          render :action => :new
        end
      end
    end
  end

  def edit
    @title = "編輯文章"
    render
  end

  def update
    @title = "編輯文章"
    respond_to do |format|
      if @news_item.update_attributes(params[:news_item])
        format.html do
          flash[:notice]= "你的網誌文章內容已更新。"
          redirect_to user_notes_path(@user)
        end
      else
        format.html do
          flash.now[:error]= "更新文章時出錯，請重新嘗試一次。"
          render :action => :edit
        end
      end
    end
  end

  def destroy
    if @news_item.can_edit?(@user)
      @news_item.destroy
      flash[:notice]= "網誌文章已成功被刪除。"
    else
      flash[:notice]= "你無法刪除這篇文章。"
    end
    respond_to do |format|
      format.html do
        redirect_to user_notes_path(@user)
      end
    end
  end

end
