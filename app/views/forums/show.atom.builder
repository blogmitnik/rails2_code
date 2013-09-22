atom_feed do |feed|
  feed.title(app_name + " 論壇主題")
  feed.updated(@forum.topics.first.created_at)

  for topic in @forum.topics
    feed.entry(topic, :url => forum_topic_url(@forum, topic.id)) do |entry|
      entry.title(topic.name)
      firstBody = (topic.forum_posts_count > 0) ? topic.posts.first.body : ''
      bdy = '這個主題共有' + topic.forum_posts_count.to_s + '篇討論文章' + '<br /><br />' + firstBody
      entry.content(bdy, :type => 'html')

      entry.author do |author|
        author.name(topic.user.name)
      end
    end
  end
end