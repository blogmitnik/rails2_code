require File.dirname(__FILE__) + '/../config/environment.rb'

FLICKR = Flickr.new(FLICKR_CACHE, FLICKR_KEY, FLICKR_SECRET)

unless FLICKR.auth.token
  frob = FLICKR.auth.getFrob
  link = FLICKR.auth.login_link
  puts
  puts link
  puts
  puts "複製 URL 並將其貼到瀏覽器的網址列上"
  gets
  FLICKR.auth.getToken(frob)
  FLICKR.auth.cache_token
end