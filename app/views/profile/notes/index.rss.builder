xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0") do
  xml.channel do
    xml.title "#{@user.name}的網誌文章"
    xml.link GlobalConfig.application_url
    xml.description "#{@user.name} 在 #{app_name}的網誌文章"
    xml.language 'en-us'
    @notes.each do |note|
      xml.item do
        xml.title note.title
        xml.description body_content(note)
        xml.author "#{@user.name}"
        xml.pubDate @user.created_at
        xml.link user_note_url(@user, note)
        xml.guid user_note_url(@user, note)
      end
    end
  end
end

