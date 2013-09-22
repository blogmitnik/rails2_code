# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.14' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# Load a global constant so the initializers can use them
require 'ostruct'
require 'yaml'

# config = OpenStruct.new(YAML.load_file("#{RAILS_ROOT}/config/global_config.yml"))
# env_config = config.send(RAILS_ENV)
# config.common.update(env_config) unless env_config.nil?
# ::GlobalConfig = OpenStruct.new(config.common)

::GlobalConfig = OpenStruct.new(YAML.load_file("#{RAILS_ROOT}/config/global_config.yml")[RAILS_ENV])

begin

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
  
  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/drops #{RAILS_ROOT}/app/filters )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  # config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  secret_file = File.join(RAILS_ROOT, "secret")  
  if File.exist?(secret_file)  
    secret = File.read(secret_file)  
  else  
    secret = Rails::SecretKeyGenerator.new("railscode").generate_secret  
    File.open(secret_file, 'w') { |f| f.write(secret) }  
  end  
  config.action_controller.session = {  
    :key => '_railscode_session',  
    :secret      => secret  
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  
  # ReCAPTCHA key variables.
  ENV['RECAPTCHA_PUBLIC_KEY'] = "6LenNAMAAAAAALMFoPx63BDrQ7jQ7EaoYLO06p5f" 
  ENV['RECAPTCHA_PRIVATE_KEY']= "6LenNAMAAAAAAPMSO7SKmq7kJtYi6zDz9md5cOnL"

  # Gem dependencies
  config.gem 'youtube-g', :version=> '0.5.0', :lib=>'youtube_g'
  config.gem 'oauth', :version => '0.4.0'
  config.gem 'nokogiri', :version => '1.5.0'
  config.gem 'crack'
  config.gem 'json'
  config.gem 'RedCloth'
  config.gem 'omniauth'
  #config.gem 'fbgraph'
  #config.gem 'omniauth-facebook'
  #config.gem 'omniauth-instagram'
  config.gem 'typhoeus'
  
  # Facebook Graph OAuth settings
  GRAPH_APP_ID = '291178277598103'
  GRAPH_SECRET = 'eedbc36185a04d5105930f128bf403c1'
  
  # Foursquare OAuth settings
  FSQ_CLIENT_ID = '3DACJXJL2W5QK55BRWVCCOCWNZWJYZVM1BAR3YND1LPFQVRU'
  FSQ_CLIENT_SECRET = 'AH1P1JPJVD510EN3UKXRO2VDQQXHSAKBTJ5WXQSRBEIG51C1'
  
  # Instagram OAuth setting
  INSTAGRAM_CLIENT_ID = 'f3eb37e1f6994d8a9442e3d85cb90df1'
  INSTAGRAM_SECRET = '9564dac4529d427e898f84afbaa1e5d3'
  
  # Twitter OAuth settings
  TWOAUTH_SITE = 'http://twitter.com'
  # Twitter OAuth callback default
  TWOAUTH_CALLBACK = 'http://railscode.mine.nu:3003/users/callback'
  # Twitter OAuth Consumer key
  TWOAUTH_KEY = 'b2TtCyuWAVi7OrdRPctg'
  # Twitter OAuth Consumer secret
  TWOAUTH_SECRET = 'W9PyMCCI83SVwRiq7yi8fJJkAq7OV4YyKswTU39id0'
  
  # Google OAuth Settings
  CONSUMER_KEY = "railscode.mine.nu"
  CONSUMER_SECRET = "MDtBu9KWUgG9yOB18csKC+no"
  PATH_TO_PRIVATE_KEY = "#{RAILS_ROOT}/config/rsakey.pem"
  
  # Linkedin OAuth settings
  LINKEDIN_SITE = 'https://api.linkedin.com'
  # Linkedin OAuth callback default
  LINKEDIN_CALLBACK = 'http://railscode.mine.nu/linkedin_callback'
  # Linkedin OAuth Consumer key
  LINKEDIN_KEY = 'QfaoWhs3HCOm8Yjj23iQ5f_DCvvtqqXuTO1VjNEdogj4qbrEaTBC7x5xLbYadSzF'
  # Linkedin OAuth Consumer secret
  LINKEDIN_SECRET = '-sP6q3IpFWDwylwDnuOIxOJRGMoE28jIpVwD6e7kix0Ar9cF8fBMc9hQrgqTuj2n'
  # Linkedin Request Token URL
  LINKEDIN_REQUEST_TOKEN = 'https://api.linkedin.com/uas/oauth/requestToken'
  # Linkedin Access Token URL
  LINKEDIN_ACCESS_TOKEN = 'https://api.linkedin.com/uas/oauth/accessToken'
  # Linkedin Authorize URL
  LINKEDIN_AUTHORIZE = 'https://api.linkedin.com/uas/oauth/authorize'
  
end
end

ActionMailer::Base.smtp_settings = {
:address => 'smtp.gmail.com',
:port => 587,
:domain => '',
:authentication => :plain,
:user_name => '',
:password => ''
}
require 'action_mailer/ar_mailer'

module Yahoo
  APPID = 'rJUi5qnIkY.YomYEHcluO5GzYxblrxdw8VWv4oWoC6U-'
end

module LiveAuth
  APPID = '000000004C0321C2'
end

class << GlobalConfig
    def prepare_options_for_attachment_fu(options)
      attachment_fu_options = options.symbolize_keys.merge({:storage => options['storage'].to_sym, 
          :max_size => options['max_size'].to_i.megabytes})  
    end
end

ENV['XD_RECEIVER_LOCATION'] = "/fb/connect/xd_receiver.html"
ENV['FACEBOOK_AUTHENTICATE_LOCATION'] = "/fb/authenticate"