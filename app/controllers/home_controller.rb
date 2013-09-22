class HomeController < ApplicationController
  
  def index
    @title = "首頁"
    @body = "home"
    @topics = Topic.find_recent
    @members = User.find_recent
    if is_logged_in?
      @user = logged_in_user
      @feed = @user.feed.paginate(:page => params[:page], :per_page => 20, :order => 'created_at desc')
      @content_pages = @user.content_pages
      @shared_uploads = @user.shared_uploads.find(:all, :limit => 5, :order => 'created_at DESC')
      @some_friends = @user.some_friends
      @requested_friends = @user.requested_friends
      @requested_memberships = @user.requested_memberships
      @invitations = @user.invitations
      @recipient = (@user.requested_friends + @user.friends + @user.pending_friends)
    else
      @feed = Activity.global_feed
    end
    respond_to do |format|
      format.html
      format.atom
      format.rss { render :layout => false }
    end  
  end
end
