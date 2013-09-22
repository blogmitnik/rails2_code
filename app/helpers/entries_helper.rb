module EntriesHelper

  def blog_title(user)
    user.blog_title ||= user.f
  end
  
  def entries_li entries
    html = ''
    entries.each do |e|
      html += "<p>#{link_to e.title, user_entry_path(@user, e)} 於 #{time_ago_in_words e.created_at} 前發佈</p>"
    end
    html
  end
  
  def entry_body_content entry
    youtube_videos = entry.body.scan(/\[youtube:+.+\]/)
    b = entry.body.dup.gsub(/\[youtube:+.+\]/, '')
    out = sanitize textilize(b)
    unless youtube_videos.empty?
    out << <<-EOB
    <strong>此文章包含下面 #{youtube_videos.size} 個影片連結：</strong><br/>
EOB
    youtube_videos.each do |o|
    out << tb_video_link(o.gsub!(/\[youtube\:|\]/, ''))
      end
    end
    out
  end
  
end
