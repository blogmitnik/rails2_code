module SearchesHelper
  
  # Return the model to be searched based on params.
  def search_model
    return "User"       if params[:controller] =~ /home/
    return "ForumPost"  if params[:controller] =~ /forums/
    return "Group"      if params[:controller] =~ /groups/ or params[:action] =~ /groups/
    return "Event"      if params[:controller] =~ /events/
    return "Friendship" if params[:controller] =~ /friends/
    params[:model] || params[:controller].classify
  end
  
  def search_type
    if params[:controller] == "forums" or params[:model] == "ForumPost"
        "討論區內容" 
    elsif params[:controller] == "messages" or params[:model] == "Message"
        "我的收件匣"
    elsif params[:controller].include?("groups") or params[:model] == "Group" or params[:action].include?("groups")
        "群組內容"
    elsif params[:controller] == "events" or params[:model] == "Event"
        "活動事件"
    elsif params[:controller] == "friends" or params[:model] == "Friendship"
        "朋友"
    else
        "使用者"
    end
  end
  
  # Return the partial (including path) for the given object.
  # partial can also accept an array of objects (of the same type).
  def partial(object)
    object = object.first if object.is_a?(Array)
    klass = object.class.to_s
    case klass
    when "ForumPost"
      dir  = "topics" 
      part = "search_result"
    when "AllUser"
      dir  = 'users'
      part = 'user'
    else
      dir  = klass.tableize  # E.g., 'Person' becomes 'people'
      part = dir.singularize # E.g., 'people' becomes 'person'
    end
    admin_search? ? "admin/#{dir}/#{part}" : "#{dir}/#{part}"
  end

  private
  
    def admin_search?
      params[:model] =~ /Admin/
    end
end
