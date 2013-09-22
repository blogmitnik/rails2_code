module ForumsHelper
  def forum_name(forum)
    forum.name.nil? || forum.name.blank? ? "Forum ##{forum.id}" : forum.name
  end

  # used to know if a topic has changed since we read it last
  def recent_topic_activity(topic)
    return false if not is_logged_in?
    return topic.replied_at > ((session[:topics] && session[:topics][topic.id]) || 3.days.ago)
  end 
  
  # used to know if a forum has changed since we read it last
  def recent_forum_activity(forum)
    return false unless is_logged_in? && forum.recent_topic
    return forum.recent_topic.replied_at > ((session[:forums] && session[:forums][forum.id]) || 3.days.ago)
  end

end
