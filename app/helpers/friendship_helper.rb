module FriendshipHelper
  def friendship_status(user, friend)
    friendship = Friendship.find_by_user_id_and_friend_id(user, friend)
    return "你們目前不是朋友" if friendship.nil?
    case friendship.status
    when 'requested'
      "他希望成為你的朋友"
    when 'pending'
      "你的邀請需要他的確認"
    when 'accepted'
      "你們現在已經是朋友"
    end
  end
  
  def friendship_status_mini(user, friend)
    friendship = Friendship.find_by_user_id_and_friend_id(user, friend)
    return "不是你的朋友" if friendship.nil?
    case friendship.status
    when 'requested'
      "需要你的確認"
    when 'pending'
      "等待對方確認"
    when 'accepted'
      "已經成為朋友"
    end
  end
end
