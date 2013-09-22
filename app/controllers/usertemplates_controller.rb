class UsertemplatesController < ApplicationController
  before_filter :login_required
  def index
    @usertemplates = @logged_in_user.usertemplates.find(:all)
    @title = "網誌模板"
    if @usertemplates.empty?
      @logged_in_user.usertemplates << Usertemplate.new(:name => 'blog_index',
                                                        :body => '')
      @logged_in_user.usertemplates << Usertemplate.new(:name => 'blog_entry',
                                                        :body => '')
      @usertemplates = @logged_in_user.usertemplates.find(:all)
    end
  end

  def edit
    @title = "編輯網誌模板"
    @usertemplate = @logged_in_user.usertemplates.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to :action => 'index'
  end

  def update
    @usertemplate = @logged_in_user.usertemplates.find(params[:id])
    if @usertemplate.update_attributes(params[:usertemplate])
      flash[:notice] = '網誌模版已成功更新'
      redirect_to usertemplates_path
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to :action => 'index'
  end
end
