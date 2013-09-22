
xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0") do
  xml.channel do
    xml.title "#{@gallery.owner.name} 的相簿"
    xml.link SITE
    xml.description "#{@gallery.owner.name} 在 #{SITE_NAME} 的相簿"
    xml.language 'en-us'
    @photos.each do |photo|
      xml.item do
        xml.title "Photo"
        xml.description "<a href=\"#{gallery_url(photo.gallery)}\" title=\"#{photo.title}\" alt=\"#{photo.gallery.title}\" class=\"thickbox\" rel=\"user_gallery\">#{image photo, :small}</a>" + photo.title
        xml.author "#{photo.owner.name}"
        xml.pubDate photo.created_at
        xml.link gallery_url(photo.gallery)
        xml.guid gallery_url(photo.gallery)
      end
    end
  end
end