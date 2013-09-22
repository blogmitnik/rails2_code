class AvatarController < ApplicationController
  before_filter :login_required

  def index
    redirect_to :action => 'upload'
  end


  def upload
    @title = "上傳個人檔案圖片"
    @user = User.find(@logged_in_user)
    if request.post?
      image = params[:avatar][:image]
      @avatar = Avatar.new(@user, image)
      @check = params[:check]
      if @check
        if @avatar.save
          flash[:notice] = "你的照片已成功上傳，你可能需要更新此頁來看到你的新照片。"
          redirect_to :action => 'upload'
        else
          flash[:notice] = "請選擇你要上傳的圖片檔案"
          render :action => 'upload'
        end
      else
        unless @user.avatar.exists?
          @user.avatar.delete
        end
        flash[:error] = "您必須保證您擁有上傳此照片的許可權，並且不會違反我們的使用條款。"
        render :action => 'upload'
      end
    end
  end
  
  def edit
    @title = "編輯個人檔案圖片"
    @user = logged_in_user
  end
  
  def delete
    user = User.find(@logged_in_user)
    if request.delete?
    user.avatar.delete
    flash[:notice] = "你的照片已成功刪除"
    redirect_to :action => 'upload'
    else
      flash[:notice] = "請用正常的方式刪除相片"
      redirect_to :action => 'upload'
    end
  end
end