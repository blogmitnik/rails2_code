module GroupsHelper
  
  def group_owner?(user,group)
    user == group.owner
  end
  
  # Return a group's image link.
  # The default is to display the group's icon linked to the profile.
  def image_link(group, options = {})
    link = options[:link] || group
    image = options[:image] || :icon
    image_options = { :title => h(group.name), :alt => h(group.name) }
    unless options[:image_options].nil?
      image_options.merge!(options[:image_options]) 
    end
    link_options =  { :title => h(group.name) }
    unless options[:link_options].nil?                    
      link_options.merge!(options[:link_options])
    end
    content = image_tag(group.send(image), image_options)
    # This is a hack needed for the way the designer handled rastered images
    # (with a 'vcard' class).
    if options[:vcard]
      content = %(#{content}#{content_tag(:span, h(group.name), :class => "fn" )})
    end
    link_to(content, link, link_options)
  end
  
  
  def group_link(group)
    link_to(group.name, group_path(group))
  end
  
  def get_groups_modes
    modes = []
    modes << ["公開式的群組",0]
    modes << ["封閉式的群組",1]
    modes << ["隱藏式的群組", 2]
    return modes
  end
  
  def can_participate?
    @can_participate == true
  end
    
  def member?
    return false if @group.nil?
    user = @user || logged_in_user
    @group.is_member?(user) || admin?
  end
    
  def manager?
    return false if @group.nil?
    user = logged_in_user
    @group.can_edit?(user)
  end
    
  def notice_message(message)
    if message && message.length > 0
      '<div class="notice">' + sanitize(message) + '</div>'
    end
  end
  
end
