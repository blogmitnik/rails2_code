xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0"){
  xml.channel do
    xml.title "#{@user.name} 的最近活動"
    xml.link SITE
    xml.description "This feed will quickly show you what has recently happened on #{SITE_NAME} without having to login."
    xml.language 'en-us'
    @recent_activity.each do |activity|
      xml.item do
      	xml.title "Activity Feed"
      	xml.description (feed_message(activity, false), :type => 'html')
      	xml.author "#{activity.owner.name}"
         xml.pubDate activity.created_at
      end
    end
  end
}