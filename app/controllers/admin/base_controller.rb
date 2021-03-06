class Admin::BaseController < ApplicationController
    before_filter :login_required 

    protected
    
    def get_user
      @user = logged_in_user
    end
        
    def authorized?
        admin?
    end

    def permission_denied      
        respond_to do |format|
            format.html do
                redirect_to home_path
            end
        end
    end
    
end