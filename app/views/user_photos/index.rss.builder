
xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0") do
  xml.channel do
    xml.title "#{@user.name} 的相片"
    xml.link SITE
    xml.description "#{@user.name} 在 #{SITE_NAME} 的相片"
    xml.language 'en-us'
    @photos.each do |photo|
      xml.item do
        xml.title "相片"
        xml.description "<a href=\"#{user_photo_url(@user, photo)}\" title=\"#{photo.title}\" alt=\"#{photo.gallery.title}\" class=\"thickbox\" rel=\"user_gallery\">#{image photo, :thumb}</a>" + photo.title
        xml.author "#{@user.name}"
        xml.pubDate photo.created_at
        xml.link user_photo_url(@user, photo)
        xml.guid user_photo_url(@user, photo)
      end
    end
  end
end