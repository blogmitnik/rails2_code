module UsersHelper

  def message_links(user)
    user.map { |p| email_link(p)}
  end

  def user_link(text, user = nil, html_options = nil)
    if user.nil?
      user = text
      text = user.name
    elsif user.is_a?(Hash)
      html_options = user
      user = text
      text = user.name
    end
    if facebook_user && user == logged_in_user
      link_to(h(facebook_user.name), profile_path(user), html_options)
    else
      link_to(h(text), profile_path(user), html_options)
    end
  end
  
  def img_link(user, options = {})
    link = options[:link] || profile_path(user)
    image = options[:image] || :icon
    image_options = { :title => h(user.name), :alt => h(user.name) }
    unless options[:image_options].nil?
      image_options.merge!(options[:image_options]) 
    end
    link_options =  { :title => h(user.name) }
    unless options[:link_options].nil?                    
      link_options.merge!(options[:link_options])
    end
    content = image_tag(user.send(image), image_options)
    # This is a hack needed for the way the designer handled rastered images
    # (with a 'vcard' class).
    if options[:vcard]
      content = %(#{content}#{content_tag(:span, h(user.name), :class => "fn" )})
    end
    if facebook_user && user == logged_in_user
      fb_uid = %(#{facebook_user})
      '<fb:profile-pic uid="' + fb_uid + '" size="square" facebook-logo="true" ></fb:profile-pic>'
    else
      link_to(content, link, link_options)
    end
  end
  
  # Same as person_link except sets up HTML needed for the image on hover effect
  def user_link_with_image(text, user = nil, html_options = nil)
    if user.nil?
      user = text
      text = user.name
    elsif user.is_a?(Hash)
      html_options = user
      user = text
      text = user.name
    end
    '<span class="imgHoverMarker">' + image_tag(user.small) + user_link(text, user, html_options) + '</span>'
  end

  def user_image_hover_text(text, user, html_options = nil)
    '<span class="imgHoverMarker">' + image_tag(user.small) + text + '</span>'
  end
  
  def enabled_status(user)
    user.enabled? ? "使用中" : "已停用"
  end
  
  def is_group_share_checked?(group, group_id)
    if group["shared"] && group.shared == "t"
      'disabled="true" checked="checked"' 
    elsif @group_id == group.id
      'checked="checked"' 
    end
  end

  def is_profile_empty?
    galleries_empty = logged_in_user.galleries.empty?
    photos_empty = logged_in_user.photos.empty?
    friends_empty = (logged_in_user.requested_friends + logged_in_user.pending_friends + logged_in_user.friends).empty?
    messages_empty = logged_in_user.sent_messages.empty?
    blog_empty = logged_in_user.notes.empty?
    galleries_empty && photos_empty && friends_empty && messages_empty && blog_empty
  end
  
  def is_profile_item_visible name
    p = @user.property(name)
    visibility = !p ? BagProperty::VISIBILITY_FRIENDS : p.visibility.to_i
    return true if visibility == BagProperty::VISIBILITY_EVERYONE
    return false if !is_logged_in?
    return true if visibility == BagProperty::VISIBILITY_USERS
    return true if visibility == BagProperty::VISIBILITY_FRIENDS && @user.friend_of?(logged_in_user)
    return true if admin?
    return false
  end
  
end
