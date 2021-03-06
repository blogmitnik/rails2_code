activities = @feed
atom_feed do |feed|
  feed.title(app_name + " 使用者活動")
  feed.updated(activities.first.updated_at)

  for activity in activities
    feed.entry(activity, :url => activity_path(activity)) do |entry|
      entry.title(strip_tags(feed_message(activity, false)))
      entry.content(feed_message(activity, false), :type => 'html')

      entry.author do |author|
        author.name(activity.owner.name)
      end
    end
  end
end