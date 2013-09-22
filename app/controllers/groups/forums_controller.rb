class Groups::ForumsController < ApplicationController
  include ForumMethods
  include GroupMethods
  before_filter :get_group
  before_filter :find_forum
  before_filter :authorize_to_show
  
  def index
    redirect_to group_forum_path(@group, @group.forums.first)
  end
  
  def show
    @title = "#{@group.name} 討論串"
    @can_participate = is_logged_in? && @group.can_participate?(logged_in_user)
    respond_to do |format|
      format.html do
        setup_show_forum
      end
      format.xml { render :xml => @forum }
    end
  end
  
  private
  
    def authorize_to_show
      unless @group && (!@group.hidden? || @group.is_member?(logged_in_user) || admin? ||
          @group.has_invited?(logged_in_user))
        redirect_back_or_default groups_path
      end
    end
  
end