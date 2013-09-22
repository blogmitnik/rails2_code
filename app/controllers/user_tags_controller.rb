class UserTagsController < ApplicationController
  before_filter :setup
  
  def index
    @title = "#{@user.name} 的相片標籤"
    @tags = @user.photos.tag_counts(:order => 'name')
  end
  
  def show
    @title = "符合 #{params[:id]} 的相片"
    @photos = @user.photos.find_tagged_with(params[:id])
  end
  
  private
  
    def setup
      @user = User.find(params[:user_id])
    end
end
