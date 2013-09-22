xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0") do
  xml.channel do
    xml.title "我與 #{@user.name} 的雙向塗鴉牆"
    xml.link GlobalConfig.application_url
    xml.description "我與 #{@user.short_name} 在 #{SITE_NAME} 的雙向塗鴉牆"
    xml.language 'en-us'
    @wall_comments.each do |c|
      xml.item do
        xml.title commentable_text(c, false)
        xml.link user_wall_comments_url(@user)
        xml.guid user_wall_comments_url(@user)
        xml.description sanitize(textilize(c.body))
        xml.author "#{c.commenter.email} (#{c.commenter.name})"
        xml.pubDate c.updated_at
      end
    end
  end
end
