module GroupMethods

  protected

  def get_group
    @group = Group.find_by_url_key(params[:group_id]) || Group.find_by_url_key(params[:id]) || Group.find(params[:group_id]) || Group.find(params[:id])
    if !@group
      flash[:notice] = "取得群組訊息時出現問題，請重新嘗試一次"
      permission_denied 
    end
  end

  def membership_required
    return true if admin?

    if !@group.can_participate?(logged_in_user)
      flash[:notice] = "你必須先成為這個群組的成員"
      permission_denied
      false
    end
  end

  # TODO decide if we need to keep this method or if we need to use authorized? from authenticated_system instead
  def authorization_required
    return true if admin?

    if !@group.can_edit?(logged_in_user)
      flash[:notice] = "你沒有權限執行這個動作"
      permission_denied
      @group = nil
      false
    end
  end

  def permission_denied      
    respond_to do |format|
      format.html do
        redirect_to index_path
      end
    end
  end

end