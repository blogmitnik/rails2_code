class NewsController < ApplicationController

  skip_filter :store_location, :only => [:index, :delete_icon]
  before_filter :login_required, :only => [:delete_icon]
  
  def index
    respond_to do |format|
      format.html { render }
    end
  end

  def delete_icon
    respond_to do |format|
      news = NewsItem.find_by_url_key(params[:id])
      news.update_attribute :icon, nil
      format.js { render(:update){|page| page.visual_effect :fade, 'avatar_edit'}}
    end      
  end

end