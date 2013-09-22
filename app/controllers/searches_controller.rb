class SearchesController < ApplicationController
  include ApplicationHelper
  before_filter :login_required

  def index
    @title = "搜尋結果"
    redirect_to(index_url) and return if params[:q].nil?
    
    query = params[:q].strip.inspect
    model = strip_admin(params[:model])
    page  = params[:page] || 1

    unless %(User Entry Message ForumPost Group Event Friendship).include?(model)
      flash[:error] = "你輸入的是不合法的搜尋內容"
      redirect_to index_url and return
    end

    if query.blank?
      @search  = [].paginate
      @results = []
    else
      filters = {}
      if model == "User" and logged_in_user.admin?
        # Find all people, including deactivated and email unverified.
        model = "AllUser"
      elsif model == "Message"
        filters['recipient_id'] = logged_in_user.id
      elsif model == "Friendship"
        model = "User"
        @user = params[:user_id].blank? ? logged_in_user : User.find(params[:user_id])
        filters['id'] = @user.friend_ids
      end
      @search = Ultrasphinx::Search.new(:query => query, 
                                        :filters => filters,
                                        :page => page, 
                                        :class_names => model)
      @search.run
      @results = @search.results
      if model == "AllUser"
        # Convert to people so that the routing works.
        @results.map!{ |user| User.find(user) }
      end
      if model == "Group"
        @results.map!{ |group| group.hidden? ? nil:group}
        @results = @results.compact
      end
    end
  rescue Ultrasphinx::UsageError
    flash[:error] = "不合法的搜尋字串"
    redirect_to searches_url(:q => "", :model => params[:model])
  end
  
  private
    
    # Strip off "Admin::" from the model name.
    # This is needed for, e.g., searches in the admin view
    def strip_admin(model)
      model.split("::").last
    end
end
