
task :demo_proxy_login => :environment do
	puts "demo_proxy_login: Starting..."

	user = User.find(:last)
	puts ".. using member #{user.screen_name}"
	twoauth = TwitterOauth.new(user.token, user.secret)

	puts ".. .. getting friends:"
	twoauth.dump_friends
	
	puts ".. .. getting followers:"
	twoauth.dump_followers
	
	puts "demo_proxy_login: Done."
end





