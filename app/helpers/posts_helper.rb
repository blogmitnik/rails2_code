module PostsHelper

  def posts_li posts
    html = ''
    posts.each do |e|
      html += "<li class='left group-post-title'>#{link_to e.title, blog_post_path(@blog, e)} - 寫於 #{time_ago_in_words e.created_at} 前</li>"
    end
    html
  end
  
end
