module ActivitiesHelper

  def x_activity_link activity
    link_to_remote image_tag('x_hide_story.gif', :class => 'actioner', :title => '移除'), 
                              :url => activity_path(activity), 
                              :confirm => "確定要刪除這則動態消息嗎？", 
                              :method => :delete
  end

  # Given an activity, return a message for the feed for the activity's class.
  def feed_message(activity, recent = false)
    owner = activity.owner
    case activity_type(activity)
    when "StatusUpdate"
      status = activity.item
      text = status.text
      time = status.created_at
      if recent
        %(#{owner.short_name}：
          #{sanitize(highlight(text, text))}。)
      else
        %(#{user_link_with_image(owner)}：
          #{sanitize(highlight(text, text))}。)
      end
    when "BlogPost"
      post = activity.item
      blog = post.blog
      view_blog = blog_link("#{h owner.name} 的日記", blog)
      if recent
        if owner.class.to_s == "User"
          %(#{owner.short_name} 張貼了一篇日記  #{link_to post.title, blog_post_path(blog, post)}。)
        elsif owner.class.to_s == "Group"
          %(#{user_link(post.user)} 張貼了一篇日記  #{link_to post.title, blog_post_path(blog, post)}。)
        end
      else
        if owner.class.to_s == "User"
          %(#{user_link_with_image(owner)} 張貼了一篇日記
            #{post_link(blog, post)}。<p>
            #{image_tag("start_quote.gif")} 
            #{sanitize(truncate(activity.item.body, 120))} 
            #{image_tag("end_quote.gif")}</p><p>
            #{post_link("繼續閱讀", blog, post)}</p>)
        elsif owner.class.to_s == "Group"
          %(#{user_link(post.user)} 張貼了一篇日記
            #{post_link(blog, post)}。<p>
            #{image_tag("start_quote.gif")} 
            #{sanitize(truncate(activity.item.body, 120))} 
            #{image_tag("end_quote.gif")}</p><p>
            #{post_link("繼續閱讀", blog, post)}</p>)
        end
      end
    when "Entry"
      entry = activity.item
      view_entry = entries_link("#{h owner.name} 的所有文章", owner)
      if recent
        %(#{owner.short_name} 分享了一篇美食評論 #{entry_link(owner, entry)}。)
      else
        %(#{user_link_with_image(owner)} 分享了一篇美食評論
          #{entry_link(owner, entry)} &mdash; #{view_entry}。<p>
          #{entry_link("繼續閱讀", owner, entry)}</p>)
      end
    when "Photo"
      photo = activity.item
      view_gallery = gallery_link("#{h photo.gallery.title}", photo.gallery)
      if recent
        if owner.class.to_s == "User"
        %(#{owner.short_name} 在相簿 #{view_gallery} 新增了相片
          #{photo_link(owner, photo)}。)
        elsif owner.class.to_s == "Group"
        %(#{user_link(photo.creator)} 在相簿 #{view_gallery} 新增了相片 
          #{photo_link(owner, photo)}。)
        end
      else
        if owner.class.to_s == "User"
          %(#{user_link_with_image(owner)} 在相簿 #{view_gallery} 新增了相片。<p>
            #{photo_image_link(photo)}</p><p class="meta">
            #{gallery_link(photo.gallery)}</p>)
        elsif owner.class.to_s == "Group"
          %(#{user_link_with_image(photo.creator)} 在相簿 #{view_gallery} 新增了相片。<p>
            #{photo_image_link(photo)}</p><p class="meta">
            #{gallery_link(photo.gallery)}</p>)
        end
      end
    when "Comment"
      entry = activity.item.entry
      user = entry.user
      if recent
       %(#{owner.short_name} 對 #{someones(entry.user, user)} 分享的美食文章
         #{entry_link("#{entry.title}", user, entry)} 發表回應。<p>
         #{image_tag("start_quote.gif")} 
         #{sanitize(truncate(activity.item.body, 120))} 
         #{image_tag("end_quote.gif")}</p>)
      else
       %(#{user_link_with_image(owner)} 對
         #{someones(entry.user, user)} 分享的美食文章
         #{entry_link("#{entry.title}", user, entry)} 發表回應。<p>
         #{image_tag("start_quote.gif")} 
         #{sanitize(truncate(activity.item.body, 120))} 
         #{image_tag("end_quote.gif")}</p>)
      end
    when "WallComment"
      parent = activity.item.commentable
      parent_type = parent.class.to_s
      case parent_type
      when "BlogPost"
        post = activity.item.commentable
        blog = post.blog
        if recent
          %(#{owner.short_name} 在 #{someones(blog.owner, owner)} 的日記
            #{link_to post.title, blog_post_path(blog, post)} 留言：<p>
            #{image_tag("start_quote.gif")} 
            #{sanitize(truncate(activity.item.body, 120))} 
            #{image_tag("end_quote.gif")}</p>)
        else
          %(#{user_link_with_image(owner)} 在
            #{someones(blog.owner, owner)} 的日記
            #{link_to post.title, blog_post_path(blog, post)} 留言：<p>
            #{image_tag("start_quote.gif")} 
            #{sanitize(truncate(activity.item.body, 120))} 
            #{image_tag("end_quote.gif")}</p>)
        end
      when "Photo"
        photo = activity.item.commentable
        user = photo.owner
        if recent
          %(#{owner.short_name} 對 #{someones(photo.owner, owner)} 的相片
            #{photo_link(user, photo)} 做了評論。<p>
            #{image_tag("start_quote.gif")} 
            #{sanitize(truncate(activity.item.body, 120))} 
            #{image_tag("end_quote.gif")}</p>)
        else
          %(#{user_link_with_image(owner)} 對
            #{someones(photo.owner, owner)} 的相片
            #{photo_link(user, photo)} 做了評論。<p>
            #{photo_image_link(photo)}</p><p class="meta">
            #{gallery_link(photo.gallery)}</p><p class="meta">
            #{image_tag("start_quote.gif")} 
            #{sanitize(truncate(activity.item.body, 80))} 
            #{image_tag("end_quote.gif")}</p>)
        end
      when "User"
        if recent
          %(#{owner.short_name} 在 #{wall(activity)} 的塗鴉牆留言。<p>
            #{image_tag("start_quote.gif")} 
            #{sanitize(truncate(activity.item.body, 120))} 
            #{image_tag("end_quote.gif")}</p>)
        else
          %(#{user_link_with_image(activity.item.commenter)}
              在 #{wall(activity)} 的塗鴉牆留言。<p>
             #{image_tag("start_quote.gif")} 
             #{sanitize(truncate(activity.item.body, 120))} 
             #{image_tag("end_quote.gif")}</p>)
        end
      when "Group"
        if recent
          %(#{owner.short_name} 在群組 #{wall(activity)} 的留言板留言。<p>
            #{image_tag("start_quote.gif")} 
            #{sanitize(truncate(activity.item.body, 120))} 
            #{image_tag("end_quote.gif")}</p>)
        else
          %(#{user_link_with_image(activity.item.commenter)} 在群組
            #{wall(activity)} 的留言板留言。<p>
            #{image_tag("start_quote.gif")} 
            #{sanitize(truncate(activity.item.body, 120))} 
            #{image_tag("end_quote.gif")}</p>)
        end
      when "Event"
        event = activity.item.commentable
        commenter = activity.item.commenter
        if event.eventable.class.to_s == "Group"
          if recent
            %(#{owner.short_name} 在群組 
              #{group_link(event.eventable)} 的活動
              #{event_link(event.title, event)} 頁面上留言。<p>
              #{image_tag("start_quote.gif")} 
              #{sanitize(truncate(activity.item.body, 120))} 
              #{image_tag("end_quote.gif")}</p>)
          else
            %(#{user_link_with_image(commenter)} 在群組 
              #{group_link(event.eventable)} 的活動
              #{event_link(event.title, event)} 頁面上留言。<p>
              #{image_tag("start_quote.gif")} 
              #{sanitize(truncate(activity.item.body, 120))} 
              #{image_tag("end_quote.gif")}</p>)
          end
        else
          if recent
            %(#{owner.short_name} 在 
              #{someones(event.user, commenter)} 建立的活動
              #{event_link(event.title, event)} 頁面上留言。<p>
              #{image_tag("start_quote.gif")} 
              #{sanitize(truncate(activity.item.body, 120))} 
              #{image_tag("end_quote.gif")}</p>)
          else
            %(#{user_link_with_image(commenter)} 在 
              #{someones(event.user, commenter)} 建立的活動
              #{event_link(event.title, event)} 頁面上留言。<p>
              #{image_tag("start_quote.gif")} 
              #{sanitize(truncate(activity.item.body, 120))} 
              #{image_tag("end_quote.gif")}</p>)
          end
        end
      when "NewsItem"
        news = activity.item.commentable
        commenter = activity.item.commenter
        if news.newsable.class.to_s == "User"
          if recent
            %(#{owner.short_name} 回覆了 
              #{someones(news.creator, commenter)} 的網誌文章
              #{note_link(news.newsable, news)}：<p>
              #{image_tag("start_quote.gif")} 
              #{sanitize(truncate(activity.item.body, 120))} 
              #{image_tag("end_quote.gif")}</p>)
          else
            %(#{user_link_with_image(commenter)} 回覆了 
              #{someones(news.creator, commenter)} 的網誌文章
              #{note_link(news.newsable, news)}：<p>
              #{image_tag("start_quote.gif")} 
              #{sanitize(truncate(activity.item.body, 120))} 
              #{image_tag("end_quote.gif")}</p>)
          end
        elsif news.newsable.class.to_s == "Group"
          if recent
            %(#{owner.short_name} 在群組 
              #{someones(news.newsable, commenter)} 的新聞訊息
              #{news_link(news.newsable, news)} 回應。<p>
              #{image_tag("start_quote.gif")} 
              #{sanitize(truncate(activity.item.body, 120))} 
              #{image_tag("end_quote.gif")}</p>)
          else
            %(#{user_link_with_image(commenter)} 在群組 
              #{someones(news.newsable, commenter)} 的新聞訊息
              #{news_link(news.newsable, news)} 回應。<p>
              #{image_tag("start_quote.gif")} 
              #{sanitize(truncate(activity.item.body, 120))} 
              #{image_tag("end_quote.gif")}</p>)
          end
        elsif news.newsable.class.to_s == "Widget"
          if recent
            %(#{owner.short_name} 在 
              #{someones(news.creator, commenter)} 張貼的新聞訊息
              #{story_link(news)} 回應。<p>
              #{image_tag("start_quote.gif")} 
              #{sanitize(truncate(activity.item.body, 120))} 
              #{image_tag("end_quote.gif")}</p>)
          else
            %(#{user_link_with_image(commenter)} 在 
              #{someones(news.creator, commenter)} 張貼的新聞訊息
              #{story_link(news)} 回應。<p>
              #{image_tag("start_quote.gif")} 
              #{sanitize(truncate(activity.item.body, 120))} 
              #{image_tag("end_quote.gif")}</p>)
          end
        end
      end
    when "Friendship"
      user = activity.item.user
      friend = activity.item.friend
      if activity.item.friend.admin?
        if recent
          %(#{owner.short_name} 加入了 #{app_name}。)
        else
          %(#{user_link_with_image(activity.item.user)}
              加入了 Cateplaces。)
        end
      else
        if recent
          %(#{owner.short_name} 和 #{user_link_with_image(activity.item.friend)} 成為了朋友。)
        else
          %(#{someones(user, friend)} 和
            #{someones(friend, user)} 現在已經成為朋友。)
        end
      end
    when "ForumPost"
      post = activity.item
      group = post.forum.forumable
      if recent
        if owner.class.to_s == "Group"
          %(#{user_link_with_image(post.user)} 貼文回覆了討論串 
            #{topic_link(post.topic)}：<p>
            #{image_tag("start_quote.gif")} 
            #{sanitize(truncate(post.body, 120))} 
            #{image_tag("end_quote.gif")}</p>)
        else
          %(#{owner.short_name} 貼文回覆討論串 
            #{topic_link(post.topic)}：<p>
            #{image_tag("start_quote.gif")} 
            #{sanitize(truncate(post.body, 120))} 
            #{image_tag("end_quote.gif")}</p>)
        end
      else
        if owner.class.to_s == "Group"
          %(#{user_link_with_image(post.user)} 貼文回覆了群組
            #{group_link(group)} 的討論串
            #{topic_link(post.topic)}：<p>
            #{image_tag("start_quote.gif")} 
            #{sanitize(truncate(post.body, 120))} 
            #{image_tag("end_quote.gif")}</p>)
        else
          %(#{user_link_with_image(owner)} 貼文回覆討論串
            #{topic_link(post.topic)}：<p>
            #{image_tag("start_quote.gif")} 
            #{sanitize(truncate(post.body, 120))} 
            #{image_tag("end_quote.gif")}</p>)
        end
      end
    when "Topic"
      topic = activity.item
      group = topic.forum.forumable
      if recent
        if owner.class.to_s == "Group"
          %(#{user_link_with_image(topic.user)} 在討論區新增了話題： 
            #{topic_link(activity.item)}。)
        else
          %(#{owner.short_name} 在討論區 
            #{site_forum_link(activity.item.forum)} 新增了話題： 
            #{topic_link(activity.item)}。)
        end
      else
        if owner.class.to_s == "Group"
          %(#{user_link_with_image(topic.user)} 在群組
            #{group_link(group)} 的討論區新增了話題：
            #{topic_link(activity.item)}。)
        else
          %(#{user_link_with_image(owner)} 在討論區 
            #{site_forum_link(activity.item.forum)} 新增了話題：
            #{topic_link(activity.item)}。)
        end
      end
    when "User"
      if recent
        %(#{owner.short_name} 修改了個人帳號資料。)
      else
        %(#{user_link_with_image(owner)} 修改了他的帳號資料。)
      end
    when "Gallery"
      if recent
        %(#{owner.short_name} 新增了一本相簿
          #{gallery_link(activity.item)}。)
      else
        %(#{user_link_with_image(owner)} 新增了一本相簿
          #{gallery_link(activity.item)}。)
      end
    when "Photo"
      if recent
        %(#{owner.short_name} 
          #{to_gallery_link(activity.item.gallery)} 新增了相片
          #{photo_link(activity.item)}。)
      else
        %(#{user_link_with_image(owner)}
          #{to_gallery_link(activity.item.gallery)} 新增了相片
          #{photo_link(activity.item)}。)
      end
    when "Event"
      event = activity.item
      time = event.start_time
      if event.eventable_type == "Group"
        if recent
          %(#{owner.short_name} 在群組
            #{group_link(event.eventable)} 建立了一項活動
            #{event_link(event.title, event)}。時間於 
            #{time.strftime('%m月%d日 %H:%M')}。)
        else
          %(#{user_link_with_image(owner)} 在群組
            #{group_link(event.eventable)} 建立了一項活動
            #{event_link(event.title, event)}。時間於 
            #{time.strftime('%y年%m月%d日 %H:%M')}。)
        end
      else
        if recent
          %(#{owner.short_name} 建立了一項活動
            #{event_link(event.title, event)}。時間於 
            #{time.strftime('%m月%d日 %H:%M')}。)
        else
          %(#{user_link_with_image(owner)} 建立了一項活動
            #{event_link(event.title, event)}。時間於 
            #{time.strftime('%y年%m月%d日 %H:%M')}。)
        end
      end
    when "EventAttendee"
      event = activity.item.event
      if event.eventable_type == "Group"
        if recent
          %(#{owner.short_name} 將出席群組
            #{group_link(event.eventable)} 召集的活動 
            #{event_link(event.title, event)}。) 
        else
          %(#{user_link_with_image(owner)} 將出席群組
            #{group_link(event.eventable)} 召集的活動 
            #{event_link(event.title, event)}。) 
        end
      else
        if recent
          %(#{owner.short_name} 將出席 
            #{someones(event.user, owner)} 召集的活動 
            #{event_link(event.title, event)}。) 
        else
          %(#{user_link_with_image(owner)} 將出席
            #{someones(event.user, owner)} 召集的活動 
            #{event_link(event.title, event)}。) 
        end
      end
    when "Group"
      if owner.class.to_s == "Group"
        if recent
              %(管理員變更了群組頁面的內容。)
        else
          %(#{group_link(activity.item)} 的管理員變更了群組頁面的內容。)
        end
      else
        if recent
          %(#{owner.short_name} 建立了一個群組 
            #{group_link(Group.find(activity.item))}。)
        else
          %(#{user_link_with_image(owner)} 建立了一個群組 
            #{group_link(Group.find(activity.item))}。)
        end
      end
    when "Membership"
      if owner.class.to_s == "Group"
        if recent
        %(#{user_link_with_image(User.find(activity.item.user))} 現在是群組的成員。)
        else
        %(#{user_link_with_image(User.find(activity.item.user))} 現在是群組 
          #{group_link(Group.find(activity.item.group))} 的成員。)
        end
      else
        if recent
          %(#{owner.short_name} 加入了 #{group_link(Group.find(activity.item.group))} 群組。)
        else
          %(#{user_link_with_image(owner)} 加入了 
            #{group_link(Group.find(activity.item.group))} 群組。)
        end
      end
    when "NewsItem"
      news = activity.item
      if owner.class.to_s == "User"
        if recent
        %(#{owner.short_name} 發表了一篇網誌文章 
          #{note_link(news.newsable, news)}。)
        else
        %(#{user_link_with_image(news.creator)} 發表了一篇網誌文章 
          #{note_link(news.newsable, news)}：<p>
          #{image_tag("start_quote.gif")} 
          #{summarize(news.body, 120)} 
          #{image_tag("end_quote.gif")}</p>)
        end
      elsif owner.class.to_s == "Group"
        group = news.newsable
        if recent
        %(#{user_link(news.creator)} 張貼了一篇新聞訊息 
          #{news_link(group, news)}。)
        else
        %(#{user_link_with_image(news.creator)} 在群組 #{group_link(news.newsable)} 張貼了一篇新聞訊息 
          #{news_link(group, news)}：<p>
          #{image_tag("start_quote.gif")} 
          #{summarize(news.body, 120)} 
          #{image_tag("end_quote.gif")}</p>)
        end
      elsif owner.class.to_s == "Widget"
        if recent
        %(#{owner.short_name} 張貼了一篇新聞文章 
          #{story_link(news)}。)
        else
        %(#{user_link_with_image(news.creator)} 張貼了一篇新聞文章 
          #{story_link(news)}。<p>
          #{image_tag("start_quote.gif")} 
          #{summarize(news.body, 120)} 
          #{image_tag("end_quote.gif")}</p>)
        end
      end
      
    else
      raise "不合法的活動類型 '#{activity_type(activity).inspect}'"
    end
  end
  
  def minifeed_message(activity)
    owner = activity.owner
    case activity_type(activity)
    when "StatusUpdate"
      status = activity.item
      text = status.text
      %(#{user_link(owner)} 更改狀態為 #{sanitize(text)})
    when "BlogPost"
      post = activity.item
      blog = post.blog
      %(#{user_link(owner)} 張貼了一篇文章
        #{post_link("#{post.title}", blog, post)})
    when "Entry"
      entry = activity.item
      user = entry.user
      %(#{user_link(owner)} 分享了一篇美食評論
        #{entry_link("#{entry.title}", user, entry)}。)
    when "Comment"
      user = activity.item.user
      entry = activity.item.entry
      %(#{user_link(owner)} 對
        #{someones(entry.user, user)} 分享的美食評論
        #{entry_link("#{entry.title}", entry.user, entry)} 發表回應。)
    when "WallComment"
      parent = activity.item.commentable
      parent_type = parent.class.to_s
      case parent_type
      when "BlogPost"
        post = activity.item.commentable
        blog = post.blog
        if blog.owner_type == "User"
          %(#{user_link(owner)} 在
            #{someones(blog.owner, owner)} 的文章
            #{post_link("#{post.title}", post.blog, post)} 留言。)
        elsif blog.owner_type == "Group"
          %(#{user_link(owner)} 在群組
            #{someones(blog.owner, owner)} 的文章
            #{link_to post.title, blog_post_path(blog, post)} 留言。)
        end
      when "User"
        %(#{user_link(activity.item.commenter)} 在 
          #{wall(activity)} 的塗鴉牆留言。)
      when "Photo"
        photo = activity.item.commentable
        user = photo.owner
        if photo.owner_type == "User"
          %(#{user_link_with_image(owner)} 對 
            #{someones(photo.owner, owner)} 的相片
            #{photo_link(user, photo)} 做了評論。)
        elsif photo.owner_type == "Group"
          %(#{user_link_with_image(owner)} 對群組 
            #{someones(photo.owner, owner)} 的相片
            #{photo_link(user, photo)} 做了評論。)
        end
      when "Event"
        event = activity.item.commentable
        %(#{user_link(activity.item.commenter)} 在 
          #{someones(event.user, activity.item.commenter)} 建立的活動 
          #{event_link("#{event.title}", event)}上留言。)
      when "Group"
        %(#{user_link(activity.item.commenter)} 在群組 
          #{wall(activity)} 的留言板留言。)
      when "NewsItem"
        news = activity.item.commentable
        if news.newsable.class.to_s == "User"
          %(#{user_link_with_image(activity.item.commenter)} 回覆了 
            #{someones(news.creator, activity.item.commenter)} 的網誌文章
            #{note_link(news.newsable, news)}。)
        elsif news.newsable.class.to_s == "Group"
          %(#{user_link(activity.item.commenter)} 在群組 
            #{someones(news.newsable, activity.item.commenter)} 的新聞訊息
            #{news_link(news.newsable, news)} 回應。)
        elsif news.newsable.class.to_s == "Widget"
          %(#{user_link_with_image(activity.item.commenter)} 在 
            #{someones(news.creator, activity.item.commenter)} 張貼的新聞訊息
            #{story_link(news)} 回應。)
        end
      end
    when "Friendship"
      if activity.item.friend.admin?
        %(#{user_link(owner)} 加入了 #{app_name}。)
      else
        %(#{user_link(owner)} 和
          #{user_link(activity.item.friend)} 成為了朋友。)
      end
    when "ForumPost"
      post = activity.item
      topic = post.topic
      if owner.class.to_s == "Group"
        %(#{user_link(post.user)} 貼文回覆群組討論串
          #{topic_link(topic)}。)
      else
        %(#{user_link(owner)} 貼文回覆討論串
          #{topic_link(topic)}。)
      end
    when "Topic"
      topic = activity.item
      if owner.class.to_s == "Group"
        %(#{user_link(topic.user)} 在群組討論區新增了話題：
          #{topic_link(activity.item)}。)
      else
        %(#{user_link(owner)} 在討論區新增了話題：
          #{topic_link(activity.item)}。)
      end
    when "User"
      %(#{user_link(owner)} 修改了個人檔案資料。)
    when "Gallery"
      %(#{user_link(owner)} 新增了一本相簿
        #{gallery_link(activity.item)}。)
    when "Photo"
      %(#{user_link(owner)} 新增了一張相片
        #{photo_link(owner, activity.item)}。)
    when "Event"
      event = activity.item
      %(#{user_link(owner)} 建立了一項活動
        #{event_link("#{event.title}", activity.item)}。)
    when "EventAttendee"
      event = activity.item.event
      %(#{user_link(owner)} 參與了
        #{someones(event.user, owner)} 建立的活動 
        #{event_link("#{event.title}", event)}。)
    when "Group"
      if owner.class.to_s == "Group"
           %(變更群組檔案頁面的內容。)
      else
        %(#{user_link(owner)} 建立了一個群組 
          #{group_link(Group.find(activity.item))}。)
      end
    when "Membership"
      %(#{user_link(owner)} 加入了 
        #{group_link(Group.find(activity.item.group))} 群組。)
    when "NewsItem"
      news = activity.item
      if owner.class.to_s == "User"
        %(#{user_link(news.creator)} 發表了一篇網誌文章 
          #{note_link(news.newsable, news)}。)
      elsif owner.class.to_s == "Group"
        group = news.newsable
        %(#{user_link(news.creator)} 在群組 #{group_link(news.newsable)} 張貼了一篇新聞訊息 
          #{news_link(group, news)}。)
      elsif owner.class.to_s == "Widget"
        %(#{user_link(news.creator)} 張貼了一篇新聞文章 
          #{story_link(news)}。)
      end
    else
      raise "不合法的活動類型 #{activity_type(activity).inspect}"
    end
  end
  
  # Given an activity, return the right icon.
  def feed_icon(activity)
    img = case activity_type(activity)
            when "StatusUpdate"
              "friend_guy.gif"
            when "BlogPost"
              "note.gif"
            when "Entry"
              "page_white_edit.png"
            when "Comment"
              "comment.png"
            when "WallComment"
              parent_type = activity.item.commentable.class.to_s
              case parent_type
              when "BlogPost"
                "comments.gif"
              when "Photo"
                "comments.gif"
              when "Event"
                "comments.gif"
              when "User"
                "wall_post.gif"
              when "Group"
                "wall_post.gif"
              when "NewsItem"
                "comments.gif"
              end
            when "Friendship"
              if activity.item.friend.admin?
                "affiliation.gif"
              else
                "friend.gif"
              end
            when "ForumPost"
              "note.png"
            when "Topic"
              "discussion.gif"
            when "User"
              "edit_profile.gif"
            when "Gallery"
              "gallery.png"
            when "Photo"
              "photo.gif"
            when "Event"
              "event.gif"
            when "EventAttendee"
              "fbpage_add.gif"
            when "Group"
              if activity.owner.class.to_s == "Group"
                "edit_profile.gif"
              else
                "group.gif"
              end
            when "Membership"
              "group.gif"
            when "NewsItem"
              if activity.owner.class.to_s == "User"
                "note.gif"
              elsif activity.owner.class.to_s == "Group"
                "marketplace.gif"
              elsif activity.owner.class.to_s == "Widget"
                "notifications.gif"
              end
            else
              raise "無法辨識活動類型 #{activity_type(activity).inspect}"
            end
    image_tag("icons/#{img}", :class => "icon")
  end

  def someones(user, commenter, link = true)
    if user == commenter
      "自己"
    elsif user == logged_in_user
      "你"
    else
      if user.class.to_s == "User"
        link ? "#{user_link_with_image(user)}" : "#{h user.name}"
      elsif user.class.to_s == "Group"
        link ? "#{group_link(user)}" : "#{h user.name}"
      elsif user.class.to_s == "Widget"
        link ? "#{user_link_with_image(user)}" : "#{h user.name}"
      end
    end
  end
  
  def blog_link(text, blog)
    link_to(text, blog_path(blog))
  end
  
  def post_link(text, blog, post = nil)
    if post.nil?
      post = blog
      blog = text
      text = post.title
    end
    link_to(text, blog_post_path(blog, post))
  end
  
  def entries_link(text, user)
    link_to(text, user_entries_path(user))
  end
  
  def entry_link(text, user, entry = nil)
    if entry.nil?
      entry = user
      user = text
      text = entry.title
    end
    link_to(text, user_entry_path(user, entry))
  end
  
  def group_link(text, group = nil)
    if group.nil?
      group = text
      text = group.name
    end
    link_to(text, group_path(group))
  end
  
  def note_link(text, user, news = nil)
    if news.nil?
      news = user
      user = text
      text = news.title
    end
    link_to(text, profile_note_path(user, news))
  end
  
  def news_link(text, group, news = nil)
    if news.nil?
      news = group
      group = text
      text = news.title
    end
    link_to(text, group_news_path(group, news))
  end
  
  def story_link(text, news = nil)
    if news.nil?
      news = text
      text = news.title
    end
    link_to(text, member_story_path(news))
  end
  
  def photo_link(text, user, photo = nil)
    if photo.nil?
      photo = user
      user = text
      text = photo.gallery.title
    end
    if user.class.to_s == "User"
      link_to(text, user_photo_path(user, photo))
    elsif user.class.to_s == "Group"
      link_to(text, group_photo_path(user, photo))
    end
  end
  
  def photo_image_link(photo, options = {})
    if photo.owner_type == "User"
    link = options[:link] || user_photo_path(photo.owner, photo)
    elsif photo.owner_type == "Group"
    link = options[:link] || group_photo_path(photo.owner, photo)
    end
    image = options[:image] || :icon
    image_options = { :title => h(photo.body), :alt => h(photo.body) }
    unless options[:image_options].nil?
      image_options.merge!(options[:image_options]) 
    end
    link_options =  { :title => h(photo.body) }
    unless options[:link_options].nil?                    
      link_options.merge!(options[:link_options])
    end
    content = image_tag(photo.public_filename('small'), image_options)
    '<div class="photo">' + link_to(content, link, link_options) + '</div>'
  end
  
  def site_forum_link(text, forum = nil)
    if forum.nil?
      forum = text
      text = forum.name
    end
    link_to(text, forum_path(forum))
  end
  
  def topic_link(text, topic = nil)
    if topic.nil?
      topic = text
      text = topic.title
    end
    if topic.forum.forumable.class.to_s == "Group"
      link_to(text, group_forum_topic_path(topic.forum.forumable, topic.forum, topic))
    else
      link_to(text, forum_topic_path(topic.forum, topic))
    end
  end
  
  def gallery_link(text, gallery = nil)
    if gallery.nil?
      gallery = text
      text = gallery.title
    end
    link_to(h(text), gallery_path(gallery))
  end
  
  def to_gallery_link(text = nil, gallery = nil)
    if text.nil?
      ''
    else
      gallery_link(text, gallery)
    end
  end

  def event_link(text, event)
    if event.eventable_type == "Group"
      link_to(text, group_event_path(event.eventable, event))
    else
      link_to(text, event_path(event))
    end
  end

  # Return a link to the wall.
  def wall(activity)
    commenter = activity.owner
    if activity.item.commentable.class.to_s == "User"
      user = activity.item.commentable
      if commenter == user
          "自己"
      elsif logged_in_user?(user)
          "你"
      else
        link_to("#{someones(user, commenter, false)}",
                profile_path(user, :anchor => "tWall"))
      end
    elsif activity.item.commentable.class.to_s == "Group"
      group = activity.item.commentable
      link_to("#{someones(group, commenter, false)}",
              group_path(group, :anchor => "tWall"))
    end
  end
  
  # Only show member photo for certain types of activity
  def posterPhoto(activity)
    shouldShow = case activity_type(activity)
    when "Photo"
      true
    when "Friendship"
      true
    else
      false
    end
    if shouldShow
      image_link(activity.owner, :image => :small)
    end
  end
  
  def avatar_icon(activity, size)
    case activity.owner.class.to_s
    when "Group"
      if activity.item.class.to_s == "Group"
        img_link(activity.item.owner, :image => size)
      elsif activity.item.class.to_s == "BlogPost"
        img_link(activity.item.user, :image => size)
      elsif activity.item.class.to_s == "ForumPost"
        img_link(activity.item.user, :image => size)
      elsif activity.item.class.to_s == "Topic"
        img_link(activity.item.user, :image => size)
      elsif activity.item.class.to_s == "Event"
        img_link(activity.item.user, :image => size)
      elsif activity.item.class.to_s == "Membership"
        img_link(activity.item.user, :image => size)
      else
        img_link(activity.item.creator, :image => size)
      end
    when "User"
      img_link(activity.owner, :image => size)
    end
  end
  
  private
  
    # Return the type of activity.
    # We switch on the class.to_s because the class itself is quite long
    # (due to ActiveRecord).
    def activity_type(activity)
      activity.item.class.to_s      
    end
end
