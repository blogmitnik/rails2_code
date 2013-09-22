class FriendsController < ApplicationController
  before_filter :login_required, :setup
  before_filter :setup_friends, :only => [:accept, :decline, :cancel, :delete]
  before_filter :authorize_view, :only => :index
  before_filter :is_friend, :only => [:edit, :update]
  
  def index
    @user = User.find(params[:user_id], :include => [:friendships => :friend])
    @friends = @user.friends.paginate(:page => params[:page], :per_page => 30)
    @title = "#{@user.name} 的所有朋友"
  end
  
  def show
    redirect_to profile_path(params[:id])
  end

  def accept
    friend = @friend
    name = friend.name
    if logged_in_user.requested_friends.include?(@friend)
      Friendship.accept(logged_in_user, @friend)
      flash[:notice] = %(<img src="/images/icons/friend_accept.gif"> 你已經成為 
                         <a href="#{profile_path(friend)}">#{name}</a> 的朋友，
                                  你現在可以編輯你們之間的關係)
    else
      flash[:notice] = "你沒有任何來自 #{@friend.name} 的朋友邀請"
    end
    redirect_to index_url
  end
  
  def decline
    if @user.requested_friends.include?(@friend)
      Friendship.breakup(@user, @friend)
      flash[:notice] = "你已經取消了 #{@friend.name} 的朋友邀請"
    else
      flash[:notice] = "你沒有任何 #{@friend.name} 的朋友邀請"
    end
    redirect_to index_url
  end
  
  def cancel
    if @user.pending_friends.include?(@friend)
      Friendship.breakup(@user, @friend)
      flash[:notice] = "你已經取消了傳送給 #{@friend.name} 的朋友邀請"
    else
      flash[:notice] = "你沒有任何傳送給 #{@friend.name} 的朋友邀請"
    end
    redirect_to index_url
  end
  
  def delete
    if @user.friends.include?(@friend)
      Friendship.breakup(@user, @friend)
      flash[:notice] = "你已經將 #{@friend.name} 從朋友列表中刪除"
    else
      flash[:notice] = "你和 #{@friend.name} 目前並不是朋友"
    end
    redirect_to index_url
  end
  
  def new
    @user = User.find(logged_in_user)
    @friend = User.find(params[:friend_id])
    if @user == @friend
      flash[:notice] = "你不能將自己加為朋友"
      redirect_to user_friends_path(:user_id => logged_in_user)
    end
    unless @user.friends.include?(@friend)
      Friendship.request(@user, @friend)
      flash[:notice] = %(<img src="/images/icons/vote.png"> 你的朋友邀請已經傳送給 #{@friend.f} 等待確認。)
      redirect_to profile_path(@friend)
    else
      redirect_to profile_path(@friend)
    end
  end
  
  def edit
    @user = User.find(logged_in_user)
    @friendship = @user.friendships.find_by_friend_id(params[:id])
    @friend = @friendship.friend if @friendship
    @title = "編輯朋友關係"
    if !@friendship
      redirect_to user_friend_path(:user_id => logged_in_user, :id => params[:id])
    end
  end

  def create
    @user = User.find(logged_in_user)
    params[:friendship][:friend_id] = params[:friend_id]
    @friendship = @user.friendships.create(params[:friendship])
    @friend = @friendship.friend if @friendship
    flash[:notice] = "#{@friend.name} 現在已經成為你的朋友"
    redirect_to user_friends_path(:user_id => logged_in_user)
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def update
    @user = User.find(logged_in_user)
    @friendship = @user.friendships.find_by_friend_id(params[:id])
    @friendship.update_attributes(params[:friendship])
    @friend = @friendship.friend if @friendship
    flash[:notice] = "你已成功更新和 #{@friend.name} 之間的朋友關係"
    redirect_to user_friends_path(:user_id => logged_in_user)
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end

  private
  
    def setup
      @body = "profile"
    end
  
    def setup_friends
      @user = logged_in_user
      @friend = User.find(params[:id])
    end
    
    def is_friend
      @user = logged_in_user
      @friend = User.find(params[:id])
      unless @user.friends.include?(@friend)
        flash[:notice] = "你必須是 #{@friend.name} 的朋友，才能編輯你們之的間關係"
        redirect_to profile_path(:id => @friend)
      end
    end
    
    def authorize_view
      @user = User.find(params[:user_id])
      unless (logged_in_user?(@user) or
              Friendship.connected?(@user, logged_in_user))
        redirect_to index_url
      end
    end
end
