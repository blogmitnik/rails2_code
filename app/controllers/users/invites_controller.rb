class Users::InvitesController < ApplicationController
  include UserMethods
  before_filter :login_required
  before_filter :get_user, :setup

  def import
    @title = "匯入通訊錄"
    @users = User.find(params[:id])
    begin
      @sites = {"gmail" => Contacts::Gmail, "yahoo" => Contacts::Yahoo, "hotmail" => Contacts::Hotmail, "aol" => Contacts::Aol, "facebook" => Contacts::Facebook, "twitter" => Contacts::Twitter}
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
    @title = "邀請人們加入 #{app_name}"
    sent_emails = false
    
    invitations = params[:checkbox].collect{|x| x if  x[1]=="1" }.compact
    invitations.each do |invitation|
      name = invitation[0].to_s
      email = invitation[0].to_s
      UserNotifier.deliver_invite(logged_in_user, email, name, params[:subject], params[:message_body])
      sent_emails = true
    end
    respond_to do |format|
      if sent_emails
        format.html do
          flash[:notice] = "你的邀請函已成功傳送給朋友"
          redirect_to index_path
        end
      else
        format.html do
          flash[:error] = "請輸入正確的電子信箱和姓名才能送出邀請函"
          render :action => :new
        end
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
      UserNotifier.deliver_invite(logged_in_user, email, name, params[:subject], params[:message_body])
      sent_emails = true
    end

    respond_to do |format|
      if sent_emails
        format.html do
          flash[:notice] = "你的邀請函已成功傳送給朋友"
          redirect_to index_path
        end
      else
        format.html do
          flash[:error] = "請輸入正確的電子信箱和姓名才能送出邀請函"
          render :action => :new
        end
      end
    end
    
  rescue => ex
    message = "請輸入完整的的電子信箱和姓名"
    respond_to do |format|
      format.html do
        flash[:error] = message
        redirect_to new_user_invite_path(@user)
      end
      format.js do
        render :update do |page|
          page << "message('" + message + "');"
        end
      end
    end

  end

  private

  def setup
    @subject = params[:subject] || "來看看我在 #{app_name} 上的個人檔案吧"
    @message_body = params[:message_body] || "嗨，邀請你跟我一起來使用 #{app_name}"
  end

end
