class NewslettersController < ApplicationController
  before_filter :check_administrator_role
  
  # GET /newsletters
  def index
    @newsletters = Newsletter.find(:all)
    @title = "即時訊息列表"
  end

  # GET /newsletters/1
  def show
    @newsletter = Newsletter.find(params[:id])
    @title = "Newsletter - #{@newsletter.subject}"
  end

  # GET /newsletters/new
  def new
    @newsletter = Newsletter.new
    @title = "建立新的即時訊息"
  end

  # GET /newsletters/1;edit
  def edit
    @newsletter = Newsletter.find_by_id_and_sent(params[:id], false)
    @title = "編輯即時訊息"
  end

  # POST /newsletters
  def create
    @newsletter = Newsletter.new(params[:newsletter])

    if @newsletter.save
      flash[:notice] = '即時訊息已成功建立並儲存'
      redirect_to newsletter_path(@newsletter)
    else
      render :action => "new"
    end
  end

  # PUT /newsletters/1
  def update
    @newsletter = Newsletter.find_by_id_and_sent(params[:id], false)

    if @newsletter.update_attributes(params[:newsletter])
      flash[:notice] = 'Newsletter已成功更新.'
      redirect_to newsletter_path(@newsletter)
    else
      render :action => "edit"
    end
  end

  # DELETE /newsletters/1
  def destroy
    @newsletter = Newsletter.find_by_id_and_sent(params[:id], false)
    @newsletter.destroy

    redirect_to newsletters_path
  end
  
  # PUT /newsletters/1;send
  def sendmails
    newsletter = Newsletter.find_by_id_and_sent(params[:id], false)
    users = User.find(:all)
    users.each do |user|
      Notifier.deliver_newsletter(user, newsletter)
    end
    newsletter.update_attribute('sent', true)
    redirect_to newsletters_path
  end
  
end