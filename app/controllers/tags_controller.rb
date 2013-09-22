class TagsController < ApplicationController
  def index
    @tags = Photo.tag_counts(:order => 'name')
    @title = "TagCloud標籤雲"
  end
  
  def show
    @photos = Photo.find_tagged_with(params[:id])
    @title = "Tag標籤"
  end
end