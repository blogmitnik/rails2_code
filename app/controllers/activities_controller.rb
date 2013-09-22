class ActivitiesController < ApplicationController
  before_filter :authorized_user, :only => :destroy

  # This gets called after activity destruction for some reason.
  def show
    render :text => ""
  end

  # DELETE /activities/1
  # DELETE /activities/1.xml
  def destroy
    @activity.destroy
    flash[:success] = "活動消息已被刪除"

    respond_to do |format|
      format.html { redirect_to(profile_url(logged_in_user)) }
      format.xml  { head :ok }
      format.js { render(:update){|page| page.visual_effect :fade, "activity_#{params[:id]}".to_sym}}
    end
  end

  private

    def authorized_user
      @activity = Activity.find(params[:id])
      unless (@activity.owner_type == "User" && logged_in_user?(@activity.owner)) ||
        (@activity.owner_type == "Group" && @activity.owner.can_edit?(logged_in_user))

      respond_to do |wants|
        wants.html do
          flash[:notice] = "你無法執行這個動作"
          redirect_to index_url
        end
        wants.js { render(:update){|page| page.alert "你無法執行這個動作"} }
      end
      end
    end

end
