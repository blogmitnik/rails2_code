class BlogsController < ApplicationController
  before_filter :login_required

  def show
    @title = "網誌文章"
    @body = "blog"
    @blog = Blog.find(params[:id])
    @posts = @blog.posts.paginate(:page => params[:page], 
                                  :per_page => 10)

    respond_to do |format|
      format.html
    end
  end
end
