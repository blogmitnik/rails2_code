class Groups::InvitesController < ApplicationController
  include GroupMethods
  before_filter :login_required
  before_filter :get_group
  before_filter :setup
  before_filter :membership_required

  def import
    @title = "匯入通訊錄"
    @users = User.find(params[:id])
    begin
      @sites = {"gmail" => Contacts::Gmail, "yahoo" => Contacts::Yahoo, "hotmail" => Contacts::Hotmail, "aol" => Contacts::Aol}
      @contacts = @sites[params[:from]].new(params[:login], params[:password]).contacts
      @users , @no_users = [], []
      @contacts.each do |contact|
        if u = User.find(:first , :conditions => "email = '#{contact[1]}'" )
          @users << u
        else
          @no_users << {:name => contact[0] , :email => contact[1]}
        end
      end
    end
    respond_to do |format|
      format.html {render :template => 'shared/_contact_list', :layout => true}
      format.xml {render :xml => @contacts.to_xml}
    end
  end
  
  def invite_them
    @title = "邀請人們加入 #{@group.name}"
    sent_emails = false
    
    invitations = params[:checkbox].collect{|x| x if  x[1]=="1" }.compact
    invitations.each do |invitation|
      name = invitation[0].to_s
      email = invitation[0].to_s
      UserNotifier.deliver_group_invite(logged_in_user, email, name, params[:subject], params[:message_body])
      sent_emails = true
    end
    respond_to do |format|
      if sent_emails
        flash[:notice] = "你已經成功邀請朋友加入 #{@group.name}"
        format.html { redirect_to(group_path(@group)) }
      else
        flash[:error] = "請輸入正確的電子信箱和姓名才能送出邀請函"
        format.html { render :action => :new }
      end
    end
  end

  def new
    @title = "邀請朋友"
    render
  end

  def create
    sent_emails = false

    params[:email].each_with_index do |email, i|
      name = params[:name][i]
      UserNotifier.deliver_group_invite(logged_in_user, @group, email, name, params[:subject], params[:message_body])
      sent_emails = true
    end

    respond_to do |format|
      if sent_emails
        format.html do
          flash[:notice] = "你的群組邀請函已成功傳送給朋友"
          redirect_to group_path(@group)
        end
      else
        format.html do
          flash.now[:error] = "請輸入正確的電子信箱和姓名才能送出邀請函"
          render :action => :new
        end
      end
    end

  end

  private

  def setup
    @user = logged_in_user
    @subject = params[:subject] || "#{@user.name} 邀請你加入 #{@group.name} 群組"
    @message_body = params[:message_body] || "嗨，邀請你一起參與我在 #{app_name} 上的群組 #{@group.name}"
  end

end
