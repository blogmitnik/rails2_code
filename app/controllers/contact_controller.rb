class ContactController < ApplicationController
  before_filter :login_required, :only => [:show, :edit, :update]
  
  def index
    redirect_to profile_path(logged_in_user)
  end
  
  def show
    @user = User.find(params[:id])
    @title = "聯絡資料"
  end

  def edit
    @title = "編輯聯絡資料"
    @user = logged_in_user
    @user.contact ||= Contact.new
    @contact = @user.contact
    rescue ActiveRecord::RecordNotFound
    redirect_to :action => 'index'
  end
  
  def update
    @user = logged_in_user
    @user.contact ||= Contact.new
    @contact = @user.contact
    if request.put?
      attribute = params[:attribute]
      case attribute
        when "基本資訊"
          try_to_update @user, attribute
        when "聯絡資料"
          try_to_update @user, attribute
        when "學歷和工作經驗"
          try_to_update @user, attribute
      end
    end
    rescue ActiveRecord::RecordNotFound
    redirect_to :action => 'edit'
  end
  
  private
  
  def try_to_update(contact, attribute)
    if @user.contact.update_attributes(params[:contact])
      flash[:notice] = "您的 #{attribute} 已經成功更新"
      redirect_to :action => "edit"
    else
      render :action => 'edit'
    end
  end

end
