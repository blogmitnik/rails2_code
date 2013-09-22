ActionController::Routing::Routes.draw do |map|

  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  map.connect 'fckeditor/check_spelling', :controller => 'fckeditor', :action => 'check_spelling'
  map.connect 'fckeditor/command', :controller => 'fckeditor', :action => 'command'
  map.connect 'fckeditor/upload', :controller => 'fckeditor', :action => 'upload'
  map.connect 'connect', :controller => 'fb_connect', :action => 'connect'
  map.connect '/fb/:action', :controller => 'fb_connect'
  map.connect 'authsub', :controller => 'users', :action => 'authsub'
  map.connect 'liveAuth', :controller => 'users', :action => 'liveAuth'
  map.connect '/auth/facebook/callback', :controller => 'fb_oauth', :action => 'callback'
  map.connect '/auth/twitter/callback', :controller => 'users', :action => 'callback'

  # RailsCoders routes
  map.index '/', :controller => 'home'
  map.about '/about', :controller => 'home', :action => 'about'
  map.admin_home '/admin/home', :controller => 'home'
  map.mobile '/mobile', :controller => 'mobile/pages', :action => 'show', :id => '1-railscoders_home'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.verify 'verify/:id', :controller => 'account', :action => 'activate'
  map.login '/login', :controller => 'account', :action => 'login'
  map.logout '/logout', :controller => 'account', :action => 'logout'
  map.openid_login '/openid_login', :controller => 'account', :action => 'openid_login'
  map.profile '/profile/:id', :controller => 'profile', :action => 'show'
  map.upload_avatar '/avatar/upload', :controller => 'avatar', :action => 'upload'
  map.delete_avatar '/avatar/delete', :controller => 'avatar', :action => 'delete'
  map.yahooLogin '/yahooLogin', :controller => 'users', :action => 'yahooLogin'
  map.yahooAuth '/yahooAuth', :controller => 'users', :action => 'yahooAuth'
  map.liveLogin '/liveLogin', :controller => 'users', :action => 'liveLogin'
  map.liveLogout '/lievLogout', :controller => 'users', :action => 'liveLogout'
  map.liveAuth '/lievAuth', :controller => 'users', :action => 'liveAuth'
  map.open_id_complete 'open_id_complete', :controller => "account",:action => "openid_authenticate", :requirements => { :method => :get }
  map.open_id_complete_on_user '/users/add_openid', :controller => 'openids', :action => "create", :requirements => { :method => :get }
  map.open_id_create '/users/openid', :controller => 'openids', :action => "new"
  map.fbOAuth '/auth/facebook', :controller => 'users', :action => 'oauth'
  map.twitterOAuth '/auth/twitter', :controller => 'users', :action => 'oauth'
  map.googleOAuth '/googleOAuth', :controller => 'users', :action => 'google_oauth'
  map.show_user '/user/:username', :controller => 'users', :action => 'show_by_username'
  map.find_friend '/findfriend', :controller => 'findfriend', :action => 'index'
  map.simple_captcha '/simple_captcha/:action', :controller => 'simple_captcha'
  map.password_reset '/password_reset', :controller => 'account', :action => 'forgot_password'
  map.show_tooltip "show_tooltip", :controller =>"profile", :action => "show_tooltip"
  map.callback_fsq_oauth '/fsq_callback', :controller => 'fsq_oauth', :action => 'callback'
  
  # Content pages (put them in the content/pages/<locale>/ directory)
  # These pages will render ruby code
  map.resources :pages
  map.content '/page/*content_page', :controller => 'content', :action => 'show_page'
  map.content '/content/*content_page', :controller => 'content', :action => 'show_page'
  map.protected_page '/protected/*content_page', :controller => 'content', :action => 'show_protected_page'
  
  map.resources :activities
  map.resources :blogs
  map.resources :reviews
  map.resources :photos
  map.resources :tags
  map.resources :comments
  map.resources :entries
  map.resources :newsletters, :member => { :sendmails => :put }
  map.resources :usertemplates
  map.resources :spec
  map.resources :info
  map.resources :contact
  map.resources :academic
  map.resources :profile, :member => { :common_friends => :get }
  map.resources :avatar
  map.resources :email
  map.resources :preferences
  map.resources :searches
  map.resources :news, :member => { :delete_icon => :delete }

  map.resources :shared_uploads, :collection => { :for_me => :get, :for_group => :get }
  
  map.resources :messages, :collection => { :sent => :get, :trash => :get },
                           :member => { :reply => :get, :undestroy => :put }
                           
  map.resources :events, :member => { :attend => :get, :unattend => :get, :delete_icon => :delete },
                         :collection => {:geolocate => :get, :showlocation => :get} do |event|
    event.resources :wall_comments
    event.resources :comments, :controller => 'events/comments'
    event.resources :photos, :controller => 'events/photos' do |photo|
        photo.resources :wall_comments
    end
  end
  map.resources :event_attendees
  map.resources :wall_comments
  
  map.resources :blogs do |blog|
    blog.resources :posts do |post|
        post.resources :wall_comments
    end
  end
  
  # forums
  map.resources :posts, :name_prefix => 'all_'
  map.resources :forums, :topics, :posts, :monitorship

  %w(forum).each do |attr|
    map.resources :posts, :name_prefix => "#{attr}_", :path_prefix => "/#{attr.pluralize}/:#{attr}_id"
  end
  
  map.resources :forums do |forum|
    forum.resources :topics do |topic|
      topic.resources :posts
      topic.resource :monitorship, :controller => :monitorships
    end
  end
  
  # forums
  map.resources :forums, :collection => {:update_positions => :post} do |forum|
    forum.resources :topics, :controller => :forum_topics do |topic|
      topic.resources :posts, :controller => :forum_posts
    end
  end
  
  # Foursquare Login
  map.resources :fsq_oauth, :collection => {:callback => :get}

  map.resources :users, 
    :collection => { :callback => :get },
    :member => { :enable => :put, 
                 :help => :get, 
                 :welcome => :get, 
                 :delete_icon => :delete, 
                 :update_twitter_status => :post, 
                 :partialfriends => :get, 
                 :partialfollowers => :get, 
                 :partialmentions => :get , 
                 :partialdms => :get } do |users|
    users.resources :openids
    users.resources :roles
    users.resources :messages
    users.resources :friends
    users.resources :spec
    users.resources :info
    users.resources :contact
    users.resources :academic
    users.resources :wall_comments
    users.resources :tags, :name_prefix => 'user_', :controller => 'user_tags'
    users.resources :notes, :controller => 'users/notes'
    users.resources :photos,
                    :name_prefix => 'user_', :controller => 'user_photos', 
                    :member => { :set_primary => :put, :set_avatar => :put, 
                                 :add_tag => :put, :remove_tag => :delete } do |photo|
      photo.resources :wall_comments
    end
    users.resources :galleries
    users.resources :invites, :controller => 'users/invites', :member => {:import => :post, :invite_them => :post}
    users.resources :status_updates, :controller => 'users/status_updates'
    users.resources :events, :controller => 'users/events'
    users.resources :uploads, :controller => 'users/uploads', :collection => { :photos => :get, :images => :get, :files => :get }, 
                                                              :has_many => [:shared_uploads]
    users.resources :entries, :controller => 'users/entries'
    users.resources :shared_entries, :controller => 'users/shared_entries'
    users.resources :status_updates, :controller => 'users/status_updates' 
  end

  map.resources :galleries do |gallery|
    gallery.resources :photos,
                      :controller => 'user_photos', 
                      :member => { :set_primary => :put, :set_avatar => :put }
  end
  
  map.resources :memberships, :member => {:unsuscribe => :delete, :suscribe => :post}

  map.resources :groups, :member => { :join => :post, :leave => :post, 
       :members => :get, :invite => :get, :invite_them => :post,
       :photos => :get, :new_photo => :post, :save_photo => :post,
       :delete_photo => :delete, :update_memberships_in => :post} do |group|
   group.resources :memberships
   group.resources :galleries
   group.resources :wall_comments
   group.resources :comments, :controller => 'groups/comments'
   group.resources :photos,
                   :name_prefix => 'group_', :controller => 'user_photos', 
                   :member => { :set_primary => :put, :set_avatar => :put, 
                                :add_tag => :put, :remove_tag => :delete } do |photo|
     photo.resources :wall_comments
   end
   group.resources :news, :controller => 'groups/news' do |news|
     news.resources :wall_comments
   end
   group.resources :invites, :controller => 'groups/invites', :member => {:import => :post, :invite_them => :post}
   group.resources :events, :controller => 'groups/events',
                            :collection => {:geolocate => :get, :showlocation => :get} do |event|
     event.resources :wall_comments
     event.resources :comments, :controller => 'events/comments'
     event.resources :photos, :controller => 'groups/events/photos' do |photo|
        photo.resources :wall_comments
     end
   end
   group.resources :activities, :controller => 'groups/activities'
   group.resources :forums, :controller => 'groups/forums', :has_many => [:topics]
   group.resources :shared_entries, :controller => 'groups/shared_entries'
   group.resources :uploads, :controller => 'groups/uploads', :collection => { :photos => :get, :images => :get, :files => :get }, 
                                                              :has_many => [:shared_uploads]
 end
 
  map.resources :profile, :member => {:groups => :get, :admin_groups => :get, :request_memberships => :get, :invitations => :get} do |user|
     user.resources :notes, :controller => 'profile/notes' do |note|
       note.resources :wall_comments
     end
     user.resources :messages
     user.resources :galleries
     user.resources :friends
     user.resources :activities, :controller => 'profile/activities'
     user.resources :wall_comments
     user.resources :comments, :controller => 'profile/comments'
  end
  
  map.resources :articles, :collection => {:admin => :get}

  map.resources :categories, :collection => {:admin => :get} do |categories|
    categories.resources :articles, :name_prefix => 'category_'
  end
  
  map.resources :ecategories, :collection => {:admin => :get} do |ecategories|
    ecategories.resources :entries, :name_prefix => 'ecategory_'
  end
  
  map.namespace :admin do |admin|
    admin.resources :users
    admin.resources :preferences
    admin.resources :groups
    admin.resources :news_items
    admin.resources :member_stories
    admin.resources :uploads, :collection => { :images => :get, :files => :get }
  end
  
  map.resources :member_stories do |member_story|
    member_story.resources :wall_comments
  end
  
  map.connect '/share', :controller => 'users/shared_entries', :action => 'new'
  
  map.root :controller => "home"

  # Mobile Routes

  map.resources :pages, 
                :controller => 'mobile/pages', 
                :path_prefix => '/mobile',
                :name_prefix => 'mobile_'
  
  map.resources :articles, 
                :controller => 'mobile/articles', 
                :path_prefix => '/mobile',
                :name_prefix => 'mobile_'

  map.resources :blogs,
                :controller => 'mobile/blogs', 
                :path_prefix => '/mobile',
                :name_prefix => 'mobile_'

  map.resources :photos, 
                :controller => 'mobile/photos', 
                :path_prefix => '/mobile',
                :name_prefix => 'mobile_'

  map.resources :categories, 
                :controller => 'mobile/categories', 
                :path_prefix => '/mobile',
                :name_prefix => 'mobile_' do |categories|
    categories.resources :articles, 
                  :controller => 'mobile/articles', 
                  :name_prefix => 'mobile_category_'
  end

  map.resources :users, 
                :controller => 'mobile/users',
                :path_prefix => '/mobile',
                :name_prefix => 'mobile_' do |users|
    users.resources :photos,
                    :controller => 'mobile/user_photos',
                    :name_prefix => 'mobile_user_'
    users.resources :entries,
                    :controller => 'mobile/entries',
                    :name_prefix => 'mobile_'
  end
  
  map.resources :forums, 
                :controller => 'mobile/forums', 
                :path_prefix => '/mobile',
                :name_prefix => 'mobile_' do |forums|
    forums.resources :topics,
                     :controller => 'mobile/topics', 
                     :name_prefix => 'mobile_' do |topics|
      topics.resources :posts,
                       :controller => 'mobile/posts', 
                       :name_prefix => 'mobile_'    
    end
  end

  map.mobile_index '/mobile', :controller => 'mobile/pages',
                              :action => 'show', 
                              :id => "1"

  map.mobile_show_user  '/mobile/user/:username', :controller => 'mobile/users', :action => 'show_by_username'
  map.mobile_all_blogs  '/mobile/blogs', :controller => 'mobile/blogs', :action => 'index'
  map.mobile_all_photos '/mobile/photos', :controller => 'mobile/photos', :action => 'index'
  
  map.mobile_login  '/mobile/login', :controller => 'mobile/account', :action => 'login'
  map.mobile_logout '/mobile/logout', :controller => 'mobile/account', :action => 'logout'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
