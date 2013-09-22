begin
  unless test?
    global_prefs = Preference.find(:first)
    if global_prefs.email_notifications?
      ActionMailer::Base.delivery_method = :smtp
      ActionMailer::Base.smtp_settings = {
        :address    => global_prefs.smtp_server,
        :port       => 587,
	     :authentication => :plain,
        :user_name => 'cateplaces@gmail.com',
        :password => 'XP2000Linux',
        :domain     => global_prefs.domain
      }
    end
  end
rescue
  # Rescue from the error raised upon first migrating
  # (needed to bootstrap the preferences).
  nil
end