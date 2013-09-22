class Users::StatusUpdatesController < ApplicationController
  include UserMethods
  before_filter :login_required
  before_filter :get_user
  before_filter :get_status_update, :only => [:destroy]

  def create
    @status_update = @user.status_updates.build(params[:status_update])
    @status_update.text.gsub!(@user.short_name, '')
    @status_update.save!
    @new_status = render_to_string(:partial => 'users/current_status', :locals => {:user => @user})
    
    # Post status update to Facebook
    if facebook_user && params[:publish_to_facebook]
      @status_update.text.gsub!(@user.short_name, '')
      facebook_user.session.post 'facebook.stream.publish', :message => "#{@status_update.text}"
    end
    
    if fbgraph_user && params[:publish_to_facebook]
      @status_update.text.gsub!(@user.short_name, '')
      client = FBGraph::Client.new(:client_id => GRAPH_APP_ID, :secret_id => GRAPH_SECRET, :token => session[:fbgraph_session])
      user = client.selection.me.info!
      client.selection.user(user[:id]).feed.publish!(:message => "#{@status_update.text}", :name => "check it!", :link => "http://www.google.com/")
    end
    
    # Post status update to Twitter
    if twitter_user? && params[:publish_to_twitter]
      @status_update.text.gsub!(@user.short_name, '')
      self.update_twitter_status!(@status_update.text)
    end
          
    respond_to do |format|
      format.html do
        redirect_to index_path
      end
      format.js do
        render :update do |page|
          page.replace_html 'current-status'.to_sym, @new_status
          page.visual_effect :highlight, "current-status-text"
          page.visual_effect :fade, "send-error"
          page << 'jQuery("#status_update").val(\'' + _("在想什麼嗎？") + '\');'
          page << "jQuery('#status-update-field').removeClass('status-update-lit');"
          page << "jQuery('#status-update-field').addClass('status-update-dim');" 
          page << 'jQuery("#status-update-field").show();'
          page << 'jQuery("#submit-button").show();'
          page << 'jQuery("#progress-bar").hide();'
          page << 'jQuery("#fb_publish").hide();'
        end
      end
    end
    
  rescue => ex
    message = "抱歉！更新狀態時出現問題。#{@status_update.errors.full_messages.to_sentence}"
    respond_to do |format|
      format.html do
        flash[:error] = message
        redirect_to index_path
      end
      format.js do
        render :update do |page|
          page << 'jQuery("#progress-bar").hide();'
          page << 'jQuery("#status-update-field").show();'
          page << 'jQuery("#submit-button").show();'
          page << 'jQuery("#send-error").show();'
        end
      end
    end

  end

  def destroy
    @status_update.destroy
    
    respond_to do |format|
      format.html do
        flash[:notice] = "你的狀態已經成功更新"
        redirect_back_or_default logged_in_user
      end
      format.js do
        @new_status = render_to_string(:partial => 'users/current_status', :locals => {:user => @user})
        render(:update) do |page|
          page.replace_html "current-status", @new_status
          page.visual_effect :pulsate, "current-status".to_sym
        end
      end
    end
  end

  def get_status_update
    @status_update = StatusUpdate.find(params[:id])
    unless @status_update.can_edit?(logged_in_user)
      respond_to do |format|
        format.html do
          flash[:notice] = "你不能執行這個動作！"
          redirect_back_or_default logged_in_user
        end
        format.js { render(:update){|page| page.alert "你不能執行這個動作！"}}
      end
    end
  end
  
  def fbpublish
    respond_to do |format|
      format.js do
        render :update do |page|
          page.insert_html :bottom, "fb_publish", :partial => 'shared/fbpublish'
        end
      end
    end
  end
  
end
