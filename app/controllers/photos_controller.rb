class PhotosController < ApplicationController
  before_filter :admin_required
  
  def index
    photos_count = Photo.count(:conditions => 'thumbnail IS NULL')
    @photo_pages = Paginator.new(self, photos_count, 12, params[:page])
    @photos = Photo.find(:all, 
                         :conditions => 'thumbnail IS NULL',
                         :order => 'created_at DESC',
                         :limit => @photo_pages.items_per_page,
                         :offset => @photo_pages.current.offset)
    @title = "所有圖片"
  end
end