module WallCommentsHelper  

  def x_comment_link user, comment
    if is_logged_in? && comment.can_edit?(logged_in_user)
      link_to_remote image_tag("icons/comment_delete.png", :title => "刪除留言"), 
							:url => user_wall_comment_path(logged_in_user, comment), :method => :delete
    end
  end
  
  def commentable_text(comment, in_html = true)
    return '' if comment.commenter.nil?
    comment_activity = render_comment(comment, in_html) 
    if comment_activity
      comment_activity + ': <br /><span class="activity-comment">' + comment.body + '</span>' 
    else
      ''
    end
  end
  
  private
  
  def render_comment(comment, in_html)
    parent = comment.commentable
    case comment.commentable_type
    when "User"
      "#{link_to_if in_html, comment.commenter.name, profile_path(comment.commenter)} 
      在 #{link_to_if in_html, parent.name + '\'s', profile_path(parent)} 的塗鴉牆留言"
    when "BlogPost"
      "#{link_to_if in_html, comment.commenter.name, profile_path(comment.commenter)} 
      在網誌文章 #{link_to_if in_html, h(parent.title), blog_post_path(parent.blog, parent)} 留言"
    when "Group"
      "#{link_to_if in_html, comment.commenter.name, profile_path(comment.commenter)} 
      在群組 #{link_to_if in_html, h(parent.name), group_path(parent)} 的塗鴉牆留言"
    when "NewsItem"
      case parent.newsable_type
      when "Group"
        "#{link_to_if in_html, comment.commenter.name, profile_path(comment.commenter)} 
        在群組的新聞訊息 #{link_to_if in_html, h(parent.title), group_news_path(parent.newsable, parent)} 留言"
      when "Widget"
        return
        "#{link_to_if in_html, comment.commenter.name, profile_path(comment.commenter)} 
        在新聞訊息 #{link_to_if in_html, h(parent.title), member_story_path(parent)} 留言"
      else # 'Site', 'Widget'
        "#{link_to_if in_html, comment.commenter.name, profile_path(comment.commenter)} 
        在新聞訊息 #{link_to_if in_html, h(parent.title), member_story_path(parent)} 留言"  
      end
    else
      ''
    end
  end
  
end
