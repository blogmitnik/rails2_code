class MembershipsController < ApplicationController
  include GroupMethods
  include GroupsHelper
  skip_filter :store_location
  before_filter :login_required
  before_filter :get_group, :only => :create
  before_filter :setup, :only => :create
  before_filter :authorize_user, :only => [:edit, :update, :destroy, :suscribe, :unsuscribe]
  
  def edit
    @title = "群組成員請求"
    @membership = Membership.find(params[:id])

    if @membership.group.users.include?(@membership.user)
      redirect_to group_path(@membership.group)
    end
  end
  
  def create
    
    respond_to do |format|
    unless @group.is_member?(logged_in_user)
      if Membership.request(logged_in_user, @group)
        if @group.public?
          flash[:notice] = "你現在已經是群組 #{@group.name} 的成員"
        else
          flash[:notice] = "你的請求已經傳送至群組管理員等待確認中"
        end
        format.html { redirect_to(group_url(@group)) }
      else
        flash[:notice] = "這是不合法的動作"
        format.html { redirect_to(group_url(@group)) }
      end
    end
    end
  end
  
  def update
    
    respond_to do |format|
      membership = @membership
      user = membership.user
      name = membership.group.name
      case params[:commit]
      when "接受請求"
        unless @membership.group.is_member?(user)
          @membership.accept
          Notifier.deliver_invitation_accepted(@membership)
          if @membership.group.can_edit?(logged_in_user)
            flash[:notice] = %(你已經接受 #{@membership.user.name} 加入 <a href="#{group_path(@membership.group)}">#{name}</a> 群組)
          else
            flash[:notice] = %(你現在已經是 <a href="#{group_path(@membership.group)}">#{name}</a> 的群組成員了)
          end
        end
      when "略過請求"
        @membership.breakup
        if @membership.group.can_edit?(logged_in_user)
          flash[:notice] = "你已經拒絕了 #{@membership.user.name} 的加入群組請求"
        else
          flash[:notice] = "你已經略過了來自 #{name} 群組的邀請"
        end
      end
      format.html { redirect_to(index_url) }
    end
  end
  
  def destroy
    @membership = Membership.find(params[:id])
    @membership.breakup
    
    respond_to do |format|
      flash[:notice] = "你已經不再是群組 #{@membership.group.name} 的成員"
      format.html { redirect_to( profile_url(logged_in_user)) }
    end
  end
  
  def unsuscribe
    @membership = Membership.find(params[:id])
    @membership.breakup
    membership = @membership
    name = membership.group.name
    
    respond_to do |format|
      flash[:notice] = "你已經將 #{membership.user.name} 從這個群組的成員中移除"
      format.html { redirect_to(members_group_path(@membership.group)) }
    end
  end
  
  def suscribe
    @membership = Membership.find(params[:id])
    @membership.accept
    membership = @membership
    name = membership.group.name
    Notifier.deliver_membership_accepted(@membership)

    respond_to do |format|
      flash[:notice] = "你已經接受 #{membership.user.name} 加入 #{name} 群組"
      format.html { redirect_to(members_group_path(@membership.group)) }
    end
  end
  
  private
  
    def setup
      if !@group
        flash[:notice] = "無法取得群組資訊，請確認你輸入的網址是否正確"
        permission_denied 
      else
        @can_participate = @group.can_participate?(logged_in_user)
      end
    end

    def authorize_user
      @membership = Membership.find(params[:id], :include => [:user, :group])
      
      if !params[:invitation].blank? or params[:action] == 'suscribe' or params[:action] == 'unsuscribe'
        unless @membership.group.can_edit?(logged_in_user)
          flash[:error] = "不合法的動作"
          redirect_to index_url
        end
      else
        unless logged_in_user?(@membership.user)
          flash[:error] = "不合法的動作"
          redirect_to index_url
        end
      end
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "你無法執行這個動作"
      redirect_to index_url
    end

end
