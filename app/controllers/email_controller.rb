class EmailController < ApplicationController
  before_filter :login_required, :only => :sendto
  
  def show
    render :action => 'reset'
  end
  
  def sendto
    @user = logged_in_user
    @recipient = User.find(params[:id])
    @friendship = @user.friendships.find_by_friend_id(params[:id])
    @title = "傳送訊息給 #{@recipient.f}"
    if @user.id == @recipient.id or !@friendship
      flash[:notice] = "你無法傳送訊息給這個使用者"
      redirect_to profile_path(logged_in_user)
    else
      if request.post?
        @message = Message.new(params[:message])
        if @message.valid?
          Notifier.deliver_message(
            :user => @user,
            :recipient => @recipient,
            :message => @message,
            :user_url => profile_url(@user),
            :reply_url => url_for(:action => "sendto", 
                                  :id => @user.id)
          )      
          flash[:notice] = "你的訊息已經透過郵件傳送給 #{@recipient.f}"
          redirect_to profile_path(@recipient)
        end
      end
    end
  end

end
