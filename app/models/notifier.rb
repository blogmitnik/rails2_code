class Notifier < ActionMailer::ARMailer
  extend PreferencesHelper
  
  def domain
    @domain ||= Notifier.global_prefs.domain
  end
  
  def server
    @server_name ||= Notifier.global_prefs.server_name
  end
  
  def wall_comment_notification(wall_comment)
    @charset = "utf8"
    recipients    wall_comment.commented_user.email_with_username
    from          "Cateplaces <cateplaces@gmail.com>"
    subject       "#{wall_comment.commenter.f} 在你的塗鴉牆上留言："
    body          :domain => server, 
                  :wall_comment => wall_comment, 
                  :wall_url => profile_path(wall_comment.commentable, :anchor => "wall"),
                  :preferences_note => preferences_note(wall_comment.commented_user)
  end
  
  def entry_comment_notification(comment)
    @charset = "utf8"
    review_owner = comment.entry.user
    recipients   review_owner.email_with_username
    from         "Cateplaces <cateplaces@gmail.com>"
    subject      "#{comment.user.name} 已對你的美食文章做出評論…"
    body         :domain => server, 
                 :comment => comment, 
                 :blog_title => comment.entry.title,
                 :review_url => user_entry_path(comment.entry.user, comment.entry, :anchor => "blog-comment"),
                 :preferences_note => preferences_note(comment.entry.user)
  end
  
  def blog_comment_notification(blog_comment)
    @charset = "utf8"
    from         "Cateplaces <cateplaces@gmail.com>"
    recipients   blog_comment.commented_user.email_with_username
    subject      "#{blog_comment.commenter.f} 已回應你的文章…"
    body         :domain => server, 
                 :blog_comment => blog_comment,
                 :post_title => blog_comment.commentable.title,
                 :post_url => blog_post_path(blog_comment.commentable.blog, blog_comment.commentable, :anchor => "blog-post-comment"),
                 :preferences_note => preferences_note(blog_comment.commented_user)
  end
  
  def group_blog_comment_notification(blog_comment)
    @charset = "utf8"
    from         "Cateplaces <cateplaces@gmail.com>"
    recipients   blog_comment.commented_user.email_with_username
    subject      "#{blog_comment.commenter.f} 已回應你的群組文章…"
    body         :domain => server, 
                 :blog_comment => blog_comment,
                 :post_title => blog_comment.commentable.title,
                 :post_url => blog_post_path(blog_comment.commentable.blog, blog_comment.commentable, :anchor => "blog-post-comment"),
                 :preferences_note => preferences_note(blog_comment.commented_user)
  end
  
  def photo_comment_notification(photo_comment)
    @charset = "utf8"
    recipients    photo_comment.commented_user.email_with_username
    from          "Cateplaces <cateplaces@gmail.com>"
    subject       "#{photo_comment.commenter.f} 已回應你的相片..."
    body          :domain => server, 
                  :photo_comment => photo_comment, 
                  :photo_title => photo_comment.commentable.gallery.title,
                  :photo_url => user_photo_path(photo_comment.commentable.owner, photo_comment.commentable, :anchor => "photo-comment"),
                  :preferences_note => preferences_note(photo_comment.commented_user)
  end
  
  def group_photo_comment_notification(photo_comment)
    @charset = "utf8"
    recipients    photo_comment.commented_user.email_with_username
    from          "Cateplaces <cateplaces@gmail.com>"
    subject       "#{photo_comment.commenter.f} 已回應你的群組相片..."
    body          :domain => server, 
                  :photo_comment => photo_comment, 
                  :photo_title => photo_comment.commentable.gallery.title,
                  :photo_url => group_photo_path(photo_comment.commentable.owner, photo_comment.commentable, :anchor => "photo-comment"),
                  :preferences_note => preferences_note(photo_comment.commented_user)
  end
  
  def event_comment_notification(event_comment)
    @charset = "utf8"
    recipients    event_comment.commented_user.email_with_username
    from          "Cateplaces <cateplaces@gmail.com>"
    subject       "#{event_comment.commenter.f} 在你的活動頁面上留言："
    body          :domain => server, 
                  :event_comment => event_comment, 
                  :event_title => event_comment.commentable.title,
                  :event_url => event_path(event_comment.commentable, :anchor => "event-comment"),
                  :preferences_note => preferences_note(event_comment.commented_user)
  end
  
  def group_comment_notification(group_comment)
    @charset = "utf8"
    recipients    group_comment.commented_user.email_with_username
    from          "Cateplaces <cateplaces@gmail.com>"
    subject       "#{group_comment.commenter.f} 在你建立的群組塗鴉牆上留言："
    body          :domain => server, 
                  :group_comment => group_comment, 
                  :group_name => group_comment.commentable.name,
                  :group_url => group_path(group_comment.commentable, :anchor => "group-wall"),
                  :preferences_note => preferences_note(group_comment.commented_user)
  end
  
  def group_news_comment_notification(news_comment)
    @charset = "utf8"
    recipients    news_comment.commented_user.email_with_username
    from          "Cateplaces <cateplaces@gmail.com>"
    subject       "#{news_comment.commenter.f} 對你的群組新聞訊息回應："
    body          :domain => server, 
                  :news_comment => news_comment, 
                  :news_title => news_comment.commentable.title,
                  :group_news_url => group_news_path(news_comment.commentable.newsable, news_comment.commentable, :anchor => "news-comment"),
                  :preferences_note => preferences_note(news_comment.commented_user)
  end
  
  def member_story_comment_notification(news_comment)
    @charset = "utf8"
    recipients    news_comment.commented_user.email_with_username
    from          "Cateplaces <cateplaces@gmail.com>"
    subject       "#{news_comment.commenter.f} 對你張貼的聞訊息回應："
    body          :domain => server, 
                  :news_comment => news_comment, 
                  :news_title => news_comment.commentable.title,
                  :member_story_url => member_story_path(news_comment.commentable, :anchor => "news-comment"),
                  :preferences_note => preferences_note(news_comment.commented_user)
  end
  
  def newsletter(user, newsletter)
    @charset = "utf8"
    recipients user.email
    from "Cateplaces <cateplaces@gmail.com>"
    subject newsletter.subject
    body :body => newsletter.body, :user => user, :domain => server
  end
  
  def message(mail)
    @charset = "utf8"
    subject     mail[:message].subject
    from        "Cateplaces <cateplaces@gmail.com>"
    recipients  mail[:recipient].email
    body        mail
  end
  
  def friend_request(mail)
    @charset = "utf8"
    subject    "你在 Cateplaces 有一個好友邀請通知"
    from       "Cateplaces <cateplaces@gmail.com>"
    recipients  mail[:friend].email
    body        mail
  end
  
  def message_notification(message)
    @charset = "utf8"
    from       "Cateplaces <cateplaces@gmail.com>"
    recipients message.recipient.email
    subject    "#{message.sender.f} 在 Cateplaces 寄了一個訊息給你...‏"
    body       :domain => server, 
               :message => message, 
               :preferences_note => preferences_note(message.recipient)
  end
  
  def connection_request(connection)
    @charset = "utf8"
    from         "Cateplaces <cateplaces@gmail.com>"
    recipients   connection.user.email
    subject      "#{connection.friend.name} 已將你新增為 Cateplaces 上的好朋友..."
    body         :domain => server,
                 :connection => connection,
                 :user_url => profile_path(connection.friend),
                 :url => user_friends_path(connection.user),
                 :preferences_note => preferences_note(connection.user)
  end
  
  def membership_public_group(membership)
    @charset = "utf8"
    from         "Cateplaces <cateplaces@gmail.com>"
    recipients   membership.group.owner.email
    subject      "#{membership.user.name} 已經加入你的公開群組「 #{membership.group.name} 」。"
    body         :domain => server,
                 :membership => membership,
                 :url => members_group_path(membership.group),
                 :preferences_note => preferences_note(membership.group.owner)
  end
  
  def membership_request(membership)
    @charset = "utf8"
    from         "Cateplaces <cateplaces@gmail.com>"
    recipients   membership.group.owner.email
    subject      "#{membership.user.name} 希望加入你的群組「 #{membership.group.name} 」。"
    body         :domain => server,
                 :membership => membership,
                 :url => members_group_path(membership.group),
                 :preferences_note => preferences_note(membership.group.owner)
  end
  
  def membership_accepted(membership)
    @charset = "utf8"
    from         "Cateplaces <cateplaces@gmail.com>"
    recipients   membership.user.email
    subject      "你現在已經成為「 #{membership.group.name} 」群組的成員。"
    body         :domain => server,
                 :membership => membership,
                 :url => group_path(membership.group),
                 :preferences_note => preferences_note(membership.user)
  end
  
  def invitation_notification(membership)
    @charset = "utf8"
    from         "Cateplaces <cateplaces@gmail.com>"
    recipients   membership.user.email
    subject      "#{membership.group.owner.f} 邀請你加入「 #{membership.group.name} 」群組。"
    body         :domain => server,
                 :membership => membership,
                 :url => edit_membership_path(membership),
                 :preferences_note => preferences_note(membership.user)
  end
  
  def invitation_accepted(membership)
    @charset = "utf8"
    from         "Cateplaces <cateplaces@gmail.com>"
    recipients   membership.group.owner.email
    subject      "#{membership.user.name} 已經接受加入你的群組「 #{membership.group.name} 」。"
    body         :domain => server,
                 :membership => membership,
                 :url => members_group_path(membership.group),
                 :preferences_note => preferences_note(membership.group.owner)
  end
  
  
  private
  
    def formatted_subject(text)
      name = Notifier.global_prefs.app_name
      label = name.blank? ? "" : "[#{name}] "
      "#{label}#{text}"
    end

    def preferences_note(user)
      %(想要掌握從 Cateplaces 收到什麼類型的電子郵件？請前往：<br>
        http://#{server}/users/#{user.to_param}/edit)
    end
end
