class CommentsController < ApplicationController
  before_filter :login_required
  
  def index
    @user = User.find(params[:user_id])
    @entry = Entry.find(params[:entry_id])
    unless @user and @entry == nil
      redirect_to user_entry_path(:user_id => @user, :id => @entry)
    end
  end
  
  def new
    @comment = Comment.new
    @entry = params[:entry_id]

    respond_to do |format|
      format.html # new.html.erb
      format.js # new.rjs
    end
  end
  
  def create
    @entry = Entry.find(params[:entry_id])
    @comment = Comment.new(:user_id => @logged_in_user.id, :body => params[:comment][:body])

    if @entry.disable_comment
      respond_to do |format|
        format.html { redirect_to user_entry_path(:user_id => @entry.user, :id => @entry)
          flash[:error] = "這篇文章的設定不允許回覆留言" }
        format.js {render :nothing => true}
      end
    else
      respond_to do |format|

        if @entry.comments << @comment
          format.html { redirect_to user_entry_path(:user_id => @entry.user, :id => @entry)
            flash[:notice] = "你的回覆已成功送出" }
          format.js # create.rjs
        else
          format.html { render :controller => 'comments', :action => 'new' }
          format.js {render :nothing => true}
        end
      end
    end
  end

  def destroy
    @entry = Entry.find_by_user_id_and_id(@logged_in_user.id, params[:entry_id], :include => :user)
    @comment = Comment.find(params[:id])
    
    respond_to do |format|
      if @comment.entry.user == logged_in_user
        @comment.destroy
        format.html { redirect_to user_entry_path(:user_id => @entry.user.id, :id => @entry.id) }
        format.js # destroy.rjs
      else
        format.html { redirect_to user_entry_path(:user_id => @entry.user.id, :id => @entry.id) }
        format.js {render :nothing => true}
      end
    end
  end
end
