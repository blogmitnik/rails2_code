module UserMethods
   
    protected
    
    # TODO decide if we need to keep this method or if we need to use authorized? from authenticated_system instead
    def authorization_required  
        return true if admin?
        
        if !is_me?(@user)
            flash[:notice] = "你沒有權限執行這個動作"
            permission_denied
            false
        end
    end

    def permission_denied      
        respond_to do |format|
            format.html do
                redirect_to profile_path(@user)
            end
        end
    end
            
    def get_user
        @user = logged_in_user
         
        if !@user
            flash[:notice] = "無法取得你的使用者資訊，請重新嘗試一次"
            permission_denied 
        end
    end

end
