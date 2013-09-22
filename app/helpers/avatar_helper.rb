module AvatarHelper

  def avatar_tag(user)
    image_tag(user.avatar.url, :border => 0)
  end
  
  def thumbnail_tag(user)
    image_tag(user.avatar.thumbnail_url, :border => 0)
  end
  
  def small_tag(user)
    image_tag(user.avatar.small_url, :border => 0)
  end
  
  def tiny_tag(user)
    image_tag(user.avatar.tiny_url, :border => 0)
  end
  
  def default_icon_tag(user)
    image_tag(user.avatar.default_icon_url, :border => 0)
  end

end