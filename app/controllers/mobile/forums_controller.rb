class Mobile::ForumsController < ForumsController
  layout 'mobile'
  
  def show
    redirect_to_mobile_topics_path(:forum_id => params[:forum_id])
  end
end