# == Schema Information
# Schema version: 32
#
# Table name: users
#
#  id                        :integer(11)     not null, primary key
#  username                  :string(255)     not null
#  email                     :string(128)     not null
#  hashed_password           :string(64)
#  enabled                   :boolean(1)      default(TRUE), not null
#  profile                   :text
#  created_at                :datetime
#  updated_at                :datetime
#  last_login_at             :datetime
#  posts_count               :integer(11)     default(0), not null
#  entries_count             :integer(11)     default(0), not null
#  blog_title                :string(255)
#  enable_comments           :boolean(1)      default(TRUE)
#  photos_count              :integer(11)
#  last_activity             :string(255)
#  last_activity_at          :datetime
#  flickr_username           :string(255)
#  flickr_id                 :string(255)
#  first_name                :string(255)     not null
#  middle_name               :string(255)
#  last_name                 :string(255)     not null
#  full_name                 :string(255)
#  remember_token            :string(255)
#  remember_token_expires_at :datetime
#  pw_reset_code             :string(40)
#  yahoo_userhash            :string(255)
#

require 'digest/sha2'
require 'rss/2.0'
require 'mime/types'
require 'mime_type_groups'
require 'crack'

class User < ActiveRecord::Base
  acts_as_authentic
  include UrlMethods
  include RssMethods
  include PropertyBagMethods
  include DatabaseMethods
  include ActivityLogger
  extend PreferencesHelper
  
  include Authentication
  include Authentication::ByCookieToken
  
  before_create :make_activation_code, :create_blog
  before_validation_on_create :make_user_openid
  before_validation :handle_nil_description
  before_update :set_old_description
  after_update :log_activity_description_changed
  after_create :connect_to_admin
  before_save :query_services, :lower_username
  before_destroy :destroy_activities, :destroy_feeds
  before_destroy :remove_orphans
  # for Linkedin OAuth Connect
  before_create :populate_oauth_user
  after_create :populate_child_models
  
  attr_protected :hashed_password, :enabled
  attr_accessor :password, :password_confirmation, :current_password, :password_forgotten, :identity_url, :sorted_photos
  
  is_indexed :fields => [ 'username', 'first_name', 'last_name', 'description', 'enabled', 'activation_code', 'reactivation_code'],
             :conditions => "enabled = true AND activation_code IS NULL AND reactivation_code IS NULL"
             
  QUESTION_SELECT = [
  "你的初吻對象是誰？", "你小學三年級的老師？", "你參加的第一場演唱會是哪一場？", "你母親的姓是什麼？", "你第一隻寵物的名字是什麼？", 
  "你小時後是在哪條路長大的？", "你父親的名字是什麼？", "你母親的生日是在哪一天？"]
  
  #Set input data character range 
  USERNAME_MIN_LENGTH = 4
  USERNAME_MAX_LENGTH = 16
  FIRST_NAME_MIN_LENGTH = 1
  FIRST_NAME_MAX_LENGTH = 20
  MIDDLE_NAME_MAX_LENGTH = 20
  LAST_NAME_MIN_LENGTH = 1
  LAST_NAME_MAX_LENGTH = 20
  FULL_NAME_MAX_LENGTH = 50
  PASSWORD_MIN_LENGTH = 6
  PASSWORD_MAX_LENGTH = 40
  EMAIL_MIN_LENGTH = 5
  EMAIL_MAX_LENGTH = 50
  WEBSITE_MAX_LENGTH = 50
  WEBLOG_MAX_LENGTH = 50
  FLICKR_MAX_LENGTH = 20
  COMMON_MAX_LENGTH = 20
  ANSWER_MAX_LENGTH = 30
  
  USERNAME_RANGE = USERNAME_MIN_LENGTH..USERNAME_MAX_LENGTH
  FIRST_NAME_RANGE = FIRST_NAME_MIN_LENGTH..FIRST_NAME_MAX_LENGTH
  LAST_NAME_RANGE = LAST_NAME_MIN_LENGTH..LAST_NAME_MAX_LENGTH
  PASSWORD_RANGE = PASSWORD_MIN_LENGTH..PASSWORD_MAX_LENGTH
  EMAIL_RANGE = EMAIL_MIN_LENGTH..EMAIL_MAX_LENGTH
  
  #Set html textfield size
  USERNAME_SIZE = 30
  FIRST_NAME_SIZE = 30
  MIDDLE_NAME_SIZE = 30
  LAST_NAME_SIZE = 30
  FULL_NAME_SIZE = 30
  PASSWORD_SIZE = 30
  EMAIL_SIZE = 30
  BLOG_TITLE_SIZE = 40
  FLICKR_ACCOUNT_SIZE = 20
  ANSWER_SIZE = 30
  FEED_SIZE = 10
  MAX_DEFAULT_FRIENDS = 12
  MAX_SHOW_FRIENDS = 30
  
  COMMON_ROWS = 6
  COMMON_COLS = 40
  COMMON_SIZE = 20
  
  MAX_DESCRIPTION = 1000
  EMAIL_REGEX = /\A[A-Z0-9\._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}\z/i
  TRASH_TIME_AGO = 1.month.ago
  SEARCH_LIMIT = 20
  SEARCH_PER_PAGE = 8
  MESSAGES_PER_PAGE = 10
  NUM_RECENT_MESSAGES = 1
  NUM_WALL_COMMENTS = 10
  NUM_RECENT = 8
  TIME_AGO_FOR_MOSTLY_ACTIVE = 1.month.ago
  
  ACCEPTED_AND_ACTIVE =  [%(status = ? AND
                            enabled = ? AND
                            activation_code IS NULL AND
                            reactivation_code IS NULL),
                            Friendship::ACCEPTED, true]
  REQUESTED_AND_ACTIVE =  [%(status = ? AND
                            enabled = ? AND
                            activation_code IS NULL AND
                            reactivation_code IS NULL),
                            Friendship::REQUESTED, true]
  PENDING_AND_ACTIVE =  [%(status = ? AND
                            enabled = ? AND
                            activation_code IS NULL AND
                            reactivation_code IS NULL),
                            Friendship::PENDING, true]
  
  has_and_belongs_to_many :roles
  has_many :articles
  has_one  :blog, :as => :owner
  has_many :blog_posts
  has_many :comments, 
           :order => "created_at DESC", 
           :dependent => :destroy
  has_many :friendships
  has_many :friends, 
           :through => :friendships,
           :conditions => ACCEPTED_AND_ACTIVE, 
           :order => "first_name, last_name"
  has_many :requested_friends, 
           :through => :friendships, 
           :source => :friend,
           :conditions => REQUESTED_AND_ACTIVE, 
           :order => "friendships.created_at"
  has_many :pending_friends, 
           :through => :friendships, 
           :source => :friend,
           :conditions => PENDING_AND_ACTIVE, 
           :order => "friendships.created_at"
  has_many :usertemplates
  has_one :profile
  has_one :spec
  has_one :info
  has_one :contact
  has_one :academic
  has_one :avatar
  has_many :feeds
  has_many :page_views, :order => 'created_at DESC'
  has_many :openids, :class_name => "UserOpenid", :dependent => :destroy
  has_many :wall_comments, :as => :commentable, :order => 'created_at DESC', :limit => NUM_WALL_COMMENTS, :dependent => :destroy
  has_many :photos, :as => :owner, :extend => TagCountsExtension, :dependent => :destroy, :order => 'created_at'
  has_many :galleries, :as => :owner

  # Forums
  has_many :moderatorships, :dependent => :destroy
  has_many :forums, :through => :moderatorships, :order => "#{Forum.table_name}.name"
  has_many :forum_posts, :dependent => :destroy
  has_many :posts, :class_name => "ForumPost", :dependent => :destroy
  has_many :topics, :dependent => :destroy
  has_many :monitorships, :dependent => :destroy
  has_many :monitored_topics, :through => :monitorships, :conditions => ["#{Monitorship.table_name}.active = ?", true], :order => "#{Topic.table_name}.replied_at desc", :source => :topic

  has_many :memberships
  has_many :own_groups, :class_name => "Group", :foreign_key => "user_id",
    :order => "name ASC"
  has_many :manage_groups, :through => :memberships, :source => :group, 
    :conditions => "status = 0 AND role = 'manager'", :order => "name ASC"
  has_many :own_not_hidden_groups, :class_name => "Group", 
    :foreign_key => "user_id", :conditions => "mode != 2", :order => "name ASC"
  has_many :own_hidden_groups, :class_name => "Group", 
    :foreign_key => "user_id", :conditions => "mode = 2", :order => "name ASC"
  has_many :groups, :through => :memberships, :source => :group, 
    :conditions => "status = 0 AND role != \'banned\'", :order => "name ASC"
  has_many :groups_not_hidden, :through => :memberships, :source => :group, 
    :conditions => "status = 0 AND mode != 2 AND role != \'banned\'", :order => "name ASC"
  has_many :unread_messages, :class_name => "Message", :foreign_key => "recipient_id", 
           :conditions => %(recipient_deleted_at IS NULL AND
                             recipient_read_at IS NULL)
                      
  with_options :class_name => "Message", :dependent => :destroy,
               :order => 'created_at DESC' do |user|
    user.has_many :_sent_messages, :foreign_key => "sender_id",
                    :conditions => "sender_deleted_at IS NULL"
    user.has_many :_received_messages, :foreign_key => "recipient_id",
                    :conditions => "recipient_deleted_at IS NULL"
  end
  has_many :status_updates
  # Blogs and NewsItems
  has_many :notes, :as => :newsable, :class_name => "NewsItem", :order => 'created_at desc', :dependent => :destroy
  has_many :news_items, :class_name => 'NewsItem', :foreign_key => 'creator_id'
  has_many :content_pages, :foreign_key => 'creator_id', :order => 'updated_at desc', :dependent => :destroy
  #Events
  has_many :events, :as => :eventable, :order => 'created_at desc', :dependent => :destroy
  has_many :event_attendees, :dependent => :destroy
  has_many :attending_events, :source => :event, :through => :event_attendees, :dependent => :destroy
  # Entries
  has_many :entries, :dependent => :destroy
  has_many :entries_shared_by_me, :class_name => 'SharedEntry', :foreign_key => 'shared_by_id', :dependent => :destroy
  has_many :google_docs, :through => :shared_entries, :source => 'entry', :conditions => 'google_doc = true', :select => "*"
  has_many :public_google_docs, :through => :shared_entries, :source => 'entry', :conditions => 'google_doc = true AND public = true', :select => "*"
  has_many :shared_links, :through => :shared_entries, :source => 'entry', :conditions => 'google_doc = false', :select => "*"
  has_many :public_shared_entries, :through => :shared_entries, :source => 'entry', :conditions => 'google_doc = false AND public = true', :select => "*"
  # items shared with the user
  has_many :shared_entries, :as => :destination, :order => 'created_at desc', :dependent => :destroy
  has_many :interesting_entries, :through => :shared_entries, :source => 'entry'
  # Files - documents, photos, etc
  has_many :uploads, :as => :uploadable, :order => 'created_at desc', :dependent => :destroy
  has_many :shared_uploads, :as => :shared_uploadable, :order => 'created_at desc', :include => :upload, :dependent => :destroy
  has_many :uploads_shared_by_me, :class_name => 'SharedUpload', :foreign_key => 'shared_by_id'
  # pages
  has_many :pages, :as => :contentable, :class_name => 'ContentPage', :order => 'created_at desc', :dependent => :destroy
  # Properties
  has_many :bag_property_values, :dependent => :destroy 
  has_many :properties, :class_name => 'BagProperty', :finder_sql => 'SELECT *, bag_properties.required, bag_property_values.svalue, bag_property_values.ivalue, COALESCE(bag_property_values.visibility, bag_properties.default_visibility) AS visibility, bag_properties.data_type, bag_properties.id AS bag_property_id FROM bag_properties LEFT OUTER JOIN bag_property_values ON bag_properties.id = bag_property_values.bag_property_id AND user_id = #{id} GROUP BY bag_properties.id ORDER BY sort, bag_properties.id'
  # Linkedin properties
  has_many :positions
  has_many :educations 
  has_many :connections
  
  validates_presence_of :username
  validates_presence_of :email_with_username
  validates_presence_of :first_name
  validates_presence_of :last_name
  validates_exclusion_of :username, 
                         :in => %w( admin administrator Administrator superuser Superuser root cateplaces Cateplaces default Default default_user Default_user admin_user Admin_user ), 
                         :on => :create, :message => "很抱歉，此使用者名稱已有人使用，請嘗試其他的暱稱。"
  validates_confirmation_of :password, :if => :password_required?, :on => :create, :message => "你輸入的兩次密碼並不符合！"
  validates_confirmation_of :password, :on => :update, :message => "你輸入的兩次密碼並不符合！"
  validates_uniqueness_of :username, :case_sensitive => false, :message => "很抱歉，此使用者名稱已有人使用，請嘗試其他的暱稱。"
  validates_uniqueness_of :email, :case_sensitive => false, :message => "很抱歉，你輸入的Email地址已被註冊過了。"
  
  validates_length_of :username, :within => USERNAME_RANGE
  validates_length_of :first_name, :within => FIRST_NAME_RANGE
  validates_length_of :last_name, :within => LAST_NAME_RANGE
  validates_length_of :email, :within => EMAIL_RANGE
  validates_length_of :password, :within => PASSWORD_RANGE, :if => :password_required?
  validates_length_of :password_confirmation, :within => PASSWORD_RANGE, :if => :password_required?
  validates_length_of :answer, :maximum => ANSWER_MAX_LENGTH, :allow_blank => true
  validates_length_of :description, :maximum => MAX_DESCRIPTION
  
  validates_format_of :username, :with => /^[A-Za-z0-9_]*$/i, :message => "使用者暱稱只能包含字母，數字，或底線"
  validates_format_of :email, :with => EMAIL_REGEX, :message => "請輸入正確的Email地址格式"
  validates_inclusion_of :question, :in => QUESTION_SELECT, :message => "請選擇正確的安全問題", 
                         :on => :update, :allow_blank => true
  
  cattr_accessor :featured_profile
  @@featured_user = {:date=>Date.today-4, :profile=>nil}
  
  class << self
    # Return the paginated active users.
    def active(page = 1)
      paginate(:all, :page => page,
                     :per_page => RASTER_PER_PAGE,
                     :conditions => conditions_for_active)
    end
    
    # Return the people who are 'mostly' active.
    def mostly_active(page = 1)
      paginate(:all, :page => page,
                     :per_page => RASTER_PER_PAGE,
                     :conditions => conditions_for_mostly_active)
    end
    
    # Return *all* the active users.
    def all_active
      find(:all, :conditions => conditions_for_active)
    end
    
    # People search.
    def search(options = {})
      query = options[:q]
      return [].paginate if query.blank? or query == "*"
      if options[:all]
        results = find_by_contents(query)
      else
        conditions = conditions_for_active
        results = find_by_contents(query, {}, :conditions => conditions)
      end
      # This is inefficient.  We'll fix it when we move to Sphinx.
      results[0...SEARCH_LIMIT].paginate(:page => options[:page],
                                         :per_page => SEARCH_PER_PAGE)
    end

    def find_recent
      find(:all, :order => "users.created_at DESC",
                 :include => :photos, :limit => NUM_RECENT)
    end
    
    def find_first_admin
      find(:first, :conditions => ["admin = ?", true],
                   :order => :created_at)
    end
  end
  
  def to_param
    "#{id}-#{username.to_safe_uri}"
  end
  
  #lowercase all username
  def lower_username
    self.username = self.username.nil? ? nil : self.username.downcase 
  end
  
  def feed_to
    [self] | self.friends | self.requested_friends # prevent duplicates in the array
  end
  
  def after_create
    self.status_updates.build(:text => "#{self.name} 加入了 #{app_name}")
  end
  
  def status
    self.status_updates.find(:first, :order => 'created_at DESC')
  end
  
  def remove_orphans
    # specify new owners for any groups they created
    Group.find(:all, :conditions => {:user_id => self.id}).each do |group|
      managers = group.users.in_role('manager')
      if !managers.empty?
        new_creator = managers.first
      else
        admin_role_id = Role.find(:first, :conditions => {:name => 'Administrator'}).id
        new_creator = Permission.find(:first, :conditions => {:role_id => admin_role_id})
      end
      group.update_attribute(:user_id, new_creator.id)
    end
  end
  
  # checks to see if a given login is already in the database
  def self.login_exists?(login)
    if User.find_by_username(login).nil?
      false
    else
      true
    end
  end

  # checks to see if a given email is already in the database
  def self.email_exists?(email)
    if User.find_by_email(email).nil?
      false
    else
      true
    end
  end
  
  ## Feeds
  def activities
    feeds.find(:all, :include => [:user,:activity], 
      :order => 'activities.created_at DESC', 
      :conditions => ["users.enabled = ? AND users.activation_code IS NULL AND 
                       users.activated_at IS NOT NULL AND 
                       users.reactivation_code IS NULL", 
                       true]).collect{|x| x.activity}
  end
  
  ## Limited Feeds
  def some_activities
    feeds.find(:all, :include => [:user,:activity], 
      :order => 'activities.created_at DESC', :limit => FEED_SIZE, 
      :conditions => ["users.enabled = ? AND users.activation_code IS NULL AND 
                       users.activated_at IS NOT NULL AND 
                       users.reactivation_code IS NULL", 
                       true]).collect{|x| x.activity}
  end
  
  # Return a person-specific activity feed.
  def feed
    len = activities.length
    if len < FEED_SIZE
      # Mix in some global activities for smaller feeds.
      global = Activity.global_feed[0...(Activity::GLOBAL_FEED_SIZE-len)]
      (activities + global).uniq.sort_by { |a| a.created_at }.reverse
    else
      activities
    end
  end
  
  # Used to show the limited feed size in Profile
  def mini_feed
    len = activities.length
    if len < FEED_SIZE
      # Mix in some global activities for smaller feeds.
      global = Activity.global_feed[0...(Activity::GLOBAL_FEED_SIZE-len)]
      (activities + global).uniq.sort_by { |a| a.created_at }.reverse
    else
      some_activities
    end
  end

  def recent_activity
    Activity.find_all_by_owner_id(self, :order => 'created_at DESC',
                                        :conditions => "owner_type = 'User'")
  end
  
  # Return some friends for the home page.
  def some_friends
    friends[(0...MAX_DEFAULT_FRIENDS)]
  end
  
  def requested_memberships
    Membership.find(:all, 
          :conditions => ['status = 2 and group_id in (?)', self.own_group_ids])
  end
  
  def invitations
    Membership.find_all_by_user_id(self, 
          :conditions => ['status = 1'], :order => 'created_at DESC')
  end

  # Friends links for the friend image raster.
  def requested_contact_links
    requested_friends.map do |f|
      connect = Friendship.conn(self, f)
      edit_friend_path(conn)
    end
  end
  
  def handle_nil_description
    self.description = "" if description.nil?
  end
  
  def active?
    if User.global_prefs.email_verifications?
      enabled? and activated_at and not reactivation_code
    else
      enabled?
    end
  end

  # Activates the user in the database.
  def activate
    @activated = true
    update_attributes(:activated_at => Time.now, :activation_code => nil)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end
  
  # Re-Activates the user in the database.
  def reactivate
    @reactivate = true
    update_attributes(:reactivated_at => Time.now, :reactivation_code => nil)
  end
  
  def no_data?
    (created_at <=> updated_at) == 0
  end
  
  def make_user_openid
    self.openids.build(:openid_url => identity_url) unless identity_url.blank?
  end
  
  def before_save
    self.hashed_password = User.encrypt(password) if !password.blank?
    if self.has_attribute?('flickr_username') && !self.flickr_username.blank?
      self.flickr_id = self.get_flickr_id
    end
  end

  def before_update
    make_reactivation_code if !self.enabled
  end

  def password_required?
    return false if self.hashed_password.blank? && self.is_facebook_user?
    return false if self.hashed_password.blank? && self.yahoo_userhash != nil
    return false if self.hashed_password.blank? && self.twitter_id != nil
    return false if self.hashed_password.blank? && self.wll_uid != nil 
    return false if self.hashed_password.blank? && self.youtube_username != nil
    !self.password.blank? || !self.current_password.blank? || !self.password_confirmation.blank?
  end
  
  def self.encrypt(string)
    return Digest::SHA256.hexdigest(string)
  end
  
  def self.authenticate(email, password)
    find_by_email_and_hashed_password_and_enabled(email, User.encrypt(password), true, 
      :conditions => "activated_at IS NOT NULL AND users.reactivation_code IS NULL")
  end
  
  def correct_password?(params)
    current_password = params[:user][:current_password]
    self.hashed_password == User.encrypt(current_password) if !current_password.blank?
  end

  def password_errors(params)
    self.password = params[:user][:password]
    self.password_confirmation = params[:user][:password_confirmation]
    valid?
    errors.add(:current_password)
  end
  
  def clear_password!
    self.password = nil
    self.password_confirmation = nil
    self.current_password = nil
  end
  
  def forgot_password
    self.password_forgotten = true
    create_pw_reset_code
  end
  
  def reset_password
    update_attributes(:pw_reset_code => nil)
  end
  
  def has_role?(rolename)
    @roles ||= self.roles.map{|role| role.name}
    return false unless @roles
    @roles.include?(rolename)
  end

  #def has_role?(rolename)
  #  self.roles.find_by_name(rolename) ? true : false
  #end

  # Friend Methods
  def friend_of? user
    user.in? friends
  end

  def followed_by? user
    user.in? pending_friends
  end

  def following? user
    user.in? requested_friends
  end
  
  def self.currently_online
    User.find(:all, :conditions => ["last_login_at > ?", Time.now-1.minutes])
  end
  
  def update_posts_count
    self.class.update_posts_count id
  end
  
  # Use to update Total Forum posts count (Group & Site Posts)
  def self.update_posts_count(id)
    User.update_all ['forum_posts_count = ?', ForumPost.count(:id, :conditions => {:user_id => id})],   ['id = ?', id]
  end
  
  # Use to update Site Forum posts count
  def self.update_site_posts_count(id)
    condition = [%(user_id = ? AND group_id IS NULL), id]
    User.update_all ['site_forum_posts_count = ?', ForumPost.count(:id, :conditions => condition)],   ['id = ?', id]
  end
  
  # Use to update Group Forum posts count
  def self.update_group_posts_count(id)
    condition = [%(user_id = ? AND group_id IS NOT NULL), id]
    User.update_all ['group_forum_posts_count = ?', ForumPost.count(:id, :conditions => condition)],   ['id = ?', id]
  end  
  
  def is_active?
    !activated_at.nil?
  end

  def can_edit?(user)
    return false if user.nil?
    self.id == user.id || user.is_admin?
  end
  
  def email_with_username
    "#{username} <#{email}>"
  end
  
  def query_services
    uri = read_attribute(:blog_link)
    rss_link = RssMethods::auto_detect_rss_url(uri)
    write_attribute(:blog_rss, rss_link) if rss_link
  end
  
  def get_flickr_id
    # build the flickr request
    flickr_request = "http://api.flickr.com/services/rest/?"
    flickr_request += "method=flickr.people.findByUsername"
    flickr_request += "&username=#{self.flickr_username}"
    flickr_request += "&api_key=#{FLICKR_API_KEY}"

    # perform the API call
    response = ""
    open(flickr_request) do |s|
      response = s.read
    end

    # parse the result
    xml_response = REXML::Document.new(response)
    if xml_response.root.attributes["stat"] == 'ok'
      xml_response.root.elements["user"].attributes["nsid"]
    else
      nil
    end
  end
  
  def flickr_feed
    # build the flickr request
    flickr_request = "http://api.flickr.com/services/rest/?"
    flickr_request += "method=flickr.people.getPublicPhotos"
    flickr_request += "&per_page=5"
    flickr_request += "&user_id=#{self.flickr_id}"
    flickr_request += "&api_key=#{FLICKR_API_KEY}"

    # perform the API call
    response = ""
    open(flickr_request) do |s|
      response = s.read
    end
    
    # parse the result
    xml_response = REXML::Document.new(response)
    if xml_response.root.attributes["stat"] == 'ok'
      flickr_photos = []
      xml_response.root.elements.each("photos/photo") do |photo|
        photo_url =  "http://farm" + photo.attributes["farm"]
        photo_url += ".static.flickr.com/" + photo.attributes["server"]+"/" + photo.attributes["id"]
        photo_url += "_" + photo.attributes["secret"]+"_t.jpg"
        flickr_photos << photo_url
      end
      return flickr_photos
    else
      nil
    end
  end
  
  def to_liquid
    UserDrop.new(self)
  end
  
  def f
    if self.first_name.blank? && self.last_name.blank?
      user.login rescue '使用者未設定姓名'
    else
       ((self.first_name || '') + ' ' + (self.last_name || '')).strip
    end
  end
  
  def linkedin_name
    ((self.linkedin_first_name || '') + ' ' + (self.linkedin_last_name || '')).strip
  end
  
  def full_name
    f
  end
  
  def short_name
    self.first_name || self.username
  end
  
  def name
    f
  end
  
  def moderator_of?(forum)
    moderatorships.count(:all, :conditions => ['forum_id = ?', (forum.is_a?(Forum) ? forum.id : forum)]) == 1
  end
  
  def avatar
    Avatar.new(self)
  end
  
  def has_wall_with user
    return false if user.blank?
    !WallComment.between_users(self, user).empty?
  end
  
  ## Message methods

  def received_messages(page = 1)
    _received_messages.paginate(:page => page, :per_page => MESSAGES_PER_PAGE)
  end

  def sent_messages(page = 1)
    _sent_messages.paginate(:page => page, :per_page => MESSAGES_PER_PAGE)
  end

  def trashed_messages(page = 1)
    conditions = [%((sender_id = :user AND sender_deleted_at > :t) OR
                    (recipient_id = :user AND recipient_deleted_at > :t)),
                  { :user => id, :t => TRASH_TIME_AGO }]
    order = 'created_at DESC'
    trashed = Message.paginate(:all, :conditions => conditions,
                                     :order => order,
                                     :page => page,
                                     :per_page => MESSAGES_PER_PAGE)
  end

  def recent_messages
    Message.find(:all,
                 :conditions => [%(recipient_id = ? AND
                                   recipient_deleted_at IS NULL AND 
                                   recipient_read_at IS NULL), id],
                 :order => "created_at DESC",
                 :limit => NUM_RECENT_MESSAGES)
  end
  
  def has_unread_messages?
    sql = %(recipient_id = :id
            AND sender_id != :id
            AND recipient_deleted_at IS NULL
            AND recipient_read_at IS NULL)
    conditions = [sql, { :id => id }]
    Message.count(:all, :conditions => conditions) > 0
  end

  ## Photo helpers
  
  def photo
    # This should only have one entry, but use 'first' to be paranoid.
    photos.find_all_by_avatar(true).first
  end

  # Return all the photos other than the primary one
  def other_photos
    photos.length > 1 ? photos - [photo] : []
  end

  def main_photo
    photo.nil? ? "n_silhouette.gif" : photo.public_filename(:avatar)
  end

  def thumb
    photo.nil? ? "s_silhouette.jpg" : photo.public_filename(:thumb)
  end
  
  def small
    photo.nil? ? "no_picture.gif" : photo.public_filename(:small)
  end
  
  def tiny
    photo.nil? ? "t_silhouette.gif" : photo.public_filename(:tiny)
  end

  def icon
    photo.nil? ? "bounded_icon.jpg" : photo.public_filename(:icon)
  end

  def bounded_icon
    photo.nil? ? "bounded_icon.jpg" : photo.public_filename(:bounded_icon)
  end

  # Return the photos ordered by primary first, then by created_at.
  # They are already ordered by created_at as per the has_many association.
  def sorted_photos
    # The call to partition ensures that the primary photo comes first.
    # photos.partition(&:primary) => [[primary], [other one, another one]]
    # flatten yields [primary, other one, another one]
    @sorted_photos ||= photos.partition(&:primary).flatten
  end
  
  # Return the common connections with the given person.
  def common_friends_with(other_user, options = {})
    (friends & other_user.friends).paginate(options)
  end
  
  def is_twitter_user?
    (twitter_id && screen_name && token && secret && profile_image_url) != nil
  end
  
  def is_youtube_user?
    (youtube_username && oauth_token && oauth_secret) != nil
  end
  
  # Facebook Connect method
  def is_facebook_user?
    fb_uid > 0
  end
  
  # Facebook Graph API method
  def is_graph_user?
    fb_user_uid > 0
  end
  
  # Foursquare OAuth method
  def is_foursquare_user?
    foursquare_uid > 0
  end
  
  def email_hash
    if !(h = read_attribute(:email_hash))
      h = write_attribute(:email_hash, build_email_hash(email))
    end
    return h
  end
  
  def email=(email)
    self.email_hash = build_email_hash(email)
    write_attribute(:email, email)
  end

  def register_with_facebook
    Facebooker::Session.create.post('facebook.connect.registerUsers', :accounts => [{:email_hash => email_hash, :account_id => id}].to_json)
  end

  def before_update
    # Re-register with Facebook if email address changed
    if !new_record? && email_changed?
      register_with_facebook
    end
  end

  def after_create
    # Register with Facebook when a new user record is created
    register_with_facebook if is_facebook_user?
  end

  # Log a user in.
  def login!(session)
    session[:user_id] = id
  end
  
  # Log a user out.
  def self.logout!(session, cookies)
    session[:user_id] = nil
    cookies.delete(:authorization_token)
  end
  
  # Remember a user for future login.
  def remember!(cookies)
    cookie_expiration = 10.years.from_now
    cookies[:remember_me] = { :value   => "1",
                              :expires =>  cookie_expiration }
    self.authorization_token =  unique_identifier
    save!
    cookies[:authorization_token] = { :value   => authorization_token,
                                      :expires => cookie_expiration }
  end
  
  # Forget a user's login status.
  def forget!(cookies)
    cookies.delete(:remember_me)
    cookies.delete(:authorization_token)
  end

  # Return true if the user wants the login status remembered.
  def remember_me?
    remember_me == "1"
  end
  
  # Linkedin Connect Methods
  # TODO - add methods to update profile info on each login or update request
  # TODO - pull status updates, specialties, and current position for connection 
  
  def picture
    if self.picture_url != nil
      url = self.picture_url
    else  
      url= "linkedin_icon_no_photo_80x80.png"
    end  
  end  
  
  def twitter_urls
    # '{\"twitter_account\":{\"provider_account_name\":[\"peteskomoroch\"],\"provider_account_id\":\"14344469\"},\"total\":\"1\"}'
    urls = nil
    if self.twitter_accounts != 'null'
      @foo = JSON.parse(self.twitter_accounts)
      urls = @foo['twitter_account']
    end
    return urls  
  end  
  
  def member_urls
    urls = nil
    if self.member_url_resources != 'null'
      @foo = JSON.parse(self.member_url_resources)
      urls = @foo['member_url']
    end
    return urls  
  end  
  
  def extract_date(date_xml)
    dateval = nil
    if date_xml
      year = date_xml['year']
      month = date_xml['month']
      if year && month
        dateval = Date.new(year.to_i, month.to_i)
      elsif year
        dateval = Date.new(year.to_i)  
      end 
    end  
    dateval 
  end
  
  def extract_position(position)
    # extract data
    # create position record
    # *** start and end dates may be missing ***           
    position_params = {}
    position_params.default = nil
    position_params[:linkedin_position_id] = position['id']
    position_params[:title] = position['title']
    if position['summary']:
      position_params[:summary] = position['summary']
    end  
    position_params[:is_current] = position['is-current']
    if position['company']:
      position_params[:company] = position['company']['name']   
    end  
    position_params[:start_date] = extract_date(position['start_date'])
    position_params[:end_date] = extract_date(position['end_date'])    
    return position_params
  end
  
  def extract_education(education)
    education_params = {}
    education_params.default = nil          
    education_params[:linkedin_education_id] = education['id']
    education_params[:school_name] = education['school_name']
    education_params[:degree] = education['degree'] 
    education_params[:field_of_study] = education['field_of_study']
    education_params[:notes] = education['notes'] 
    education_params[:start_date] = extract_date(education['start_date'])
    education_params[:end_date] = extract_date(education['end_date'])
    return education_params
  end
  
  def extract_connection(person)
    # extract data
    connection_params = {}
    connection_params.default = nil
    connection_params[:logged_in_url] = person['site_standard_profile_request']['url']
    connection_params[:member_id] = connection_params[:logged_in_url].split('&')[1].split('=')[1].to_i
    connection_params[:first_name] = person['first_name']
    connection_params[:last_name] = person['last_name']
    connection_params[:headline] = person['headline']
    connection_params[:location] = person['location']['name']
    connection_params[:country] = person['location']['country']['code']  
    connection_params[:industry] = person['industry']                      
    connection_params[:picture_url] = person['picture_url']
    return connection_params
  end
  
  def extract_member_urls(member_urls)
    member_url_resources = nil
    if member_urls['total'].to_i > 1    
      member_url_resources = member_urls
    elsif member_urls['total'].to_i == 1
      member_url_resources = member_urls
      member_url_resources["member_url"] = [member_urls["member_url"]]
    end
    return member_url_resources.to_json
  end  
  
  def extract_twitter_ids(twitter_accounts)
    #twitter_account:
    # provider_account_name: peteskomoroch
    # provider_account_id: 14344469
    # total: 1
    twitter_account_resources = nil
    if twitter_accounts['total'].to_i > 1    
      twitter_account_resources = twitter_accounts
    elsif twitter_accounts['total'].to_i == 1
      twitter_account_resources = twitter_accounts
      twitter_account_resources["twitter_account"] = [twitter_account_resources["twitter_account"]]
    end
    return twitter_account_resources.to_json
  end
  
  # For LinkedIn OAuth method
  def populate_oauth_user
    unless oauth_token.blank?
      # 1) Fetch profile info (name, headline, industry, profile pic, public url, summary, specialties, web urls)
      # @response = UserSession.oauth_consumer.request(:get, 'http://api.linkedin.com/v1/people/~',
      @response = UserSession.oauth_consumer.request(:get, 
      'http://api.linkedin.com/v1/people/~:(id,first-name,last-name,headline,industry,summary,specialties,interests,picture-url,public-profile-url,site-standard-profile-request,location,twitter-accounts,member-url-resources,honors,associations)',
      access_token, { :scheme => :query_string })
      case @response
      when Net::HTTPSuccess
        #user_info = Profile.from_xml(get(path))
        user_info = Crack::XML.parse(@response.body)['person']
        self.member_id_token = user_info['id']
        self.logged_in_url = user_info['site_standard_profile_request']['url']
        self.member_id = self.logged_in_url.split('&')[1].split('=')[1]       
        self.linkedin_first_name = user_info['first_name']
        self.linkedin_last_name = user_info['last_name']
        self.headline = user_info['headline'] 
        self.industry = user_info['industry'] 
        self.summary = user_info['summary'] 
        self.specialties = user_info['specialties'] 
        self.interests = user_info['interests'] 
        self.picture_url = user_info['picture_url'] 
        self.public_profile_url = user_info['public_profile_url'] 
        self.location = user_info['location']['name'] 
        self.country = user_info['location']['country']['code']
        self.honors = user_info['honors']
        self.associations = user_info['associations']
        self.twitter_accounts = extract_twitter_ids(user_info['twitter_accounts'])           
        self.member_url_resources = extract_member_urls(user_info['member_url_resources'])
        self.hashed_password = ''
      end
    end
  end
  
  # For LinkedIn OAuth method
  def populate_child_models 
    unless oauth_token.blank?     
      @response = UserSession.oauth_consumer.request(:get, 
      'http://api.linkedin.com/v1/people/~:(id,positions,educations,connections)',
      access_token, { :scheme => :query_string })
      case @response
      when Net::HTTPSuccess
        user_info = Crack::XML.parse(@response.body)['person'] 
        
        # 2) Save past position info for user (companies, job titles, durations, descriptions) 
        if user_info['positions']['total'].to_i > 1    
          user_info['positions']['position'].each do |position|
            position_params = extract_position(position)
            self.positions.create(position_params)
          end
        else
          position_params = extract_position(user_info['positions']['position'])
          self.positions.create(position_params)
        end 

        # 3) Save education info for user (schools, degrees, field of study, dates, etc)    
        if user_info['educations']['total'].to_i > 1    
          user_info['educations']['education'].each do |education|
            education_params = extract_education(education)
            self.educations.create(education_params)
          end
        else
          education_params = extract_education(user_info['educations']['education'])
          self.educations.create(education_params)
        end    

        # 4) Save connections info - names, industries, headlines, profile pics,
        # Use Connections model
        if user_info['connections']['total'].to_i > 1    
          user_info['connections']['person'].each do |person|
            connection_params = extract_connection(person)
            self.connections.create(connection_params)
          end
        else
          connection_params = extract_connection(user_info['connections']['person'])
          self.connections.create(connection_params)
        end
           
      end
      
    end
  end
  
  
  protected
  
    def create_pw_reset_code
      self.pw_reset_code = Digest::SHA1.hexdigest("secret-#{Time.now}")
    end
    
    def make_activation_code
      self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end
    
    def make_reactivation_code
      self.reactivation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end
  
    def handle_nil_description
      self.description = "" if description.nil?
    end

    def set_old_description
      @old_description = User.find(self).description
    end

    def log_activity_description_changed
      unless @old_description == description or description.blank?
        add_activities(:item => self, :user => self, :owner => self)
      end
    end
    
    # Clear out all activities associated with this person.
    def destroy_activities
      Activity.find_all_by_user_id(self).each {|a| a.destroy}
    end
    
    def destroy_feeds
      Feed.find_all_by_user_id(self).each {|f| f.destroy}
    end
    
    def destroy_groups
      Group.find_all_by_user_id(self).each {|g| g.destroy}
    end
    
    def connect_to_admin
      tom = User.find_first_admin
      unless tom.nil? or tom == self
        Friendship.connect(self, tom)
      end
    end
  
  class << self
    # Return the conditions for a user to be active.
    def conditions_for_active
      [%(enabled = ? AND activation_code IS NULL AND
        activated_at IS NOT NULL AND reactivation_code IS NULL),
        true]
    end
    
    # Return the conditions for a user to be 'mostly' active.
    def conditions_for_mostly_active
      [%(enabled = ? AND activation_code IS NULL AND
         activated_at IS NOT NULL AND reactivation_code IS NULL AND
         (last_login_at IS NOT NULL AND last_login_at >= ?)),
       true, TIME_AGO_FOR_MOSTLY_ACTIVE]
    end
  end

  private
  
    def build_email_hash(email)
      str = email.strip.downcase
      "#{Zlib.crc32(str)}_#{Digest::MD5.hexdigest(str)}"
    end
    
    # Generate a unique identifier for a user.
    def unique_identifier
      Digest::SHA1.hexdigest("#{screen_name}:#{password}")
    end
  
end
