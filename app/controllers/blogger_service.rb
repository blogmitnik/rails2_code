class BloggerService < ActionWebService::Base
  web_service_api BloggerAPI

  def getUsersBlogs(appkey, username, password)
    if @user = User.authenticate(email, password)
      [BloggerStructs::Blog.new(
        :url => "http://localhost:3003/users/#{@user.id}/entries",
        :blogId => @user.id,
        :blogName => @user.blog_title ||= @user.f
      )]
    end
  end
  
  def getPost(appkey, postid, email, password)
    if @user = User.authenticate(email, password)
      entry = @user.entries.find(postid)
      BloggerStructs::Post.new(
        :userId => @user.id,
        :postId => entry.id,
        :dateCreated => entry.created_at.to_s(:db),
        :content => [entry.body]
      )
    end
  end

  def getRecentPosts(appkey, blogid, email, password, numberofposts)
    if @user = User.authenticate(email, password)
      @user.entries.find(:all, 
                         :order => 'created_at DESC', 
                         :limit => numberofposts).collect do |entry|
        BloggerStructs::Post.new(
          :userId => entry.user_id,
          :postId => entry.id,
          :dateCreated => entry.created_at.to_s(:db),
          :content => entry.body
        )
      end
    end
  end

  def getUserInfo(appkey, email, password)
    if @user = User.authenticate(email, password)
      BloggerStructs::User.new(
        :userId => @user.id,
        :email => @user.email,
        :url => "http://localhost:3003/users/#{@user.id}/entries"
      )
    end
  end

  def newPost(appkey, blogid, email, password, content, publish)
    if @user = User.authenticate(email, password)
      entry = Entry.new
      entry.title = "New entry"
      entry.body = content.to_s
      entry.user = @user
      entry.save
      return entry.id
    end
  end

  def editPost(appkey, postid, email, password, content, publish)
    if @user = User.authenticate(email, password)
      entry = @user.entries.find(postid)
      entry.body = content
      entry.save
      return true
    end
  end
end
