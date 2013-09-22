xm.item do
  xm.title "#{h(post.user.name)} 在 #{post.created_at.strftime('%m月%d日 %H:%M')} 回覆:"
  xm.description post.body_html
  xm.pubDate post.created_at.strftime('%m月%d日 %H:%M')
  xm.guid [request.host_with_port+request.relative_url_root, post.forum_id.to_s, post.topic_id.to_s, post.id.to_s].join(":"), "isPermaLink" => "false"
  xm.author "#{post.user.name}"
  xm.link forum_topic_url(post.forum_id, post.topic_id)
end
