class MessagesController < ApplicationController

  before_filter :login_required, :setup
  before_filter :authenticate_user, :only => [:show]
  before_filter :handle_cancel, :only => [:create]

  # GET /messages
  def index
    @title = "收件匣"
    @messages = logged_in_user.received_messages(params[:page])
    @recipient = logged_in_user.friends
    
    if logged_in_user.received_messages.empty?
      flash[:notice] = "你的收件匣中沒有訊息，你現在可以寫訊息給朋友"
      @recipient = (logged_in_user.requested_friends + logged_in_user.friends + logged_in_user.pending_friends)
      redirect_to new_message_path and return
    end
    respond_to do |format|
      format.html { render :template => "messages/index" }
    end
  end

  # GET /messages/sent
  def sent
    @title = "寄件備份"
    @messages = logged_in_user.sent_messages(params[:page])
    @recipient = logged_in_user.friends
    respond_to do |format|
      format.html { render :template => "messages/index" }
    end
  end
  
  # GET /messages/trash
  def trash
    @title = "垃圾筒"
    @messages = logged_in_user.trashed_messages(params[:page])
    @recipient = logged_in_user.friends
    respond_to do |format|
      format.html { render :template => "messages/index" }
    end    
  end

  def show
    @title = "收件匣"
    @message ||= logged_in_user.received_messages.find params[:id] rescue nil
    @message.mark_as_read if logged_in_user?(@message.recipient)
    @recipient = [@message.sender]
    respond_to do |format|
      format.html
    end
  end

  def new
    @title = "傳送訊息"
    @message = Message.new
    @recipient = (logged_in_user.requested_friends + logged_in_user.friends + logged_in_user.pending_friends)
    render
  end

  def reply
    @title = "回覆訊息"
    original_message = Message.find(params[:id])
    recipient = original_message.other_user(logged_in_user)
    @message = Message.new(:parent_id => original_message.id,
                           :subject => original_message.subject,
                           :content => original_message.content,
                           :sender => logged_in_user,
                           :recipient => recipient)
    @recipient = [@message.recipient]
    respond_to do |format|
      format.html { render :action => "new" }
    end    
  end

  def create
    @message = Message.new(params[:message])
    @message.sender = logged_in_user
    @message.recipient = @recipient
    @message = Message.new(params[:message].merge(:sender => logged_in_user,
                             :recipient => @recipient))                
    respond_to do |wants|
      if !preview? and @message.save
        wants.js do
          render :update do |page|
            page.alert "你的訊息已經成功傳送給 #{@message.recipient.name}"
            page.visual_effect :fade, "send-message-error"
            page << "jQuery('#message_subject, #message_body').val('');"
            page << 'jQuery("#compose-message-form").show();'
            page << 'jQuery("#progress-bar").hide();' 
            page << 'jQuery("#send-mail-progress").hide();'
            page << "tb_remove()"
          end
        end
  	   else
        @title = "預覽訊息"
        @preview = @message.content if preview?
        format.html { render :action => "new" }
      end
    end
    
  rescue => ex
    message = "請輸入完整的的信件標題和內容"
    respond_to do |format|
      format.html do
        flash[:error] = message
        redirect_to new_messages_path
      end
      format.js do
        render :update do |page|
          page << 'jQuery("#progress-bar").hide();'
          page << 'jQuery("#send-mail-progress").hide();'
          page << 'jQuery("#compose-message-form").show();'
          page << 'jQuery("#send-message-error").show();'
          page << "tb_remove()"
        end
      end
    end
  end

  def destroy
    @message = Message.find(params[:id])
    if @message.trash(logged_in_user)
      flash[:notice] = "你所選擇的訊息已經被移到垃圾桶中"
    else
      # This should never happen...
      flash[:error] = "你執行的是不合法的動作"
    end
  
    respond_to do |format|
      format.html { redirect_to messages_url }
    end
  end
  
  def undestroy
    @message = Message.find(params[:id])
    if @message.untrash(logged_in_user)
      flash[:notice] = "你所選擇的訊息已成功還原到收件匣"
    else
      # This should never happen...
      flash[:error] = "你執行的是不合法的動作"
    end
    respond_to do |format|
      format.html { redirect_to messages_url }
    end
  end

  private
  
    def setup
      @body = "messages"
    end
  
    def authenticate_user
      @message = Message.find(params[:id])
      unless (logged_in_user == @message.sender or
              logged_in_user == @message.recipient)
        redirect_to login_url
      end
    end

    def handle_cancel
      redirect_to messages_url if params[:commit] == "取消"
    end

    def reply?
      not params[:message][:parent_id].nil?
    end

    def not_logged_in_user(message)
      message.sender == logged_in_user ? message.recipient : message.sender
    end

    def preview?
      params["commit"] == "預覽"
    end

end