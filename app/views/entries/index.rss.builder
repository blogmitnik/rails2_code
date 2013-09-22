
xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0") do
  xml.channel do
    xml.title "#{@user.name} 的美食評論"
    xml.link SITE
    xml.description "#{@user.name} 在 #{SITE_NAME} 的美食評論"
    xml.language 'en-us'
    @entries.each do |entry|
      xml.item do
        xml.title entry.title
        xml.description entry_body_content(entry)
        xml.author "#{@user.name}"
        xml.pubDate entry.created_at
        xml.link user_entry_url(@user, entry)
        xml.guid user_entry_url(@user, entry)
      end
    end
  end
end