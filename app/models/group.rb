class Group < ActiveRecord::Base
  include ActivityLogger
  include SecureMethods
  
  acts_as_taggable_on :tags
  
  validates_presence_of :name, :description, :user_id
  validates_uniqueness_of :name
  
  NUM_WALL_COMMENTS = 5
  
  # give the group a permalink
  has_permalink :name, :url_key
  
  has_one :blog, :as => :owner
  has_many :photos, :as => :owner, :dependent => :destroy, :order => "created_at"
  has_many :memberships, :dependent => :destroy
  has_many :users, :through => :memberships, 
           :conditions => "status = 0 AND banned != true", 
           :order => "first_name, last_name", 
           :select => 'users.*, memberships.role',
           :source => :user do
             def in_role(role, options = {})
              find :all, { :conditions => ['role = ?' , role.to_s] }.merge(options)
             end
           end
  has_many :manager, :through => :memberships, :source => "user",
           :conditions => "status = 0 AND banned != true AND role = 'manager'",
           :order => "last_name, first_name"
  has_many :pending_request, :through => :memberships, :source => "user",
           :conditions => "status = 2", :order => "last_name, first_name"
  has_many :pending_invitations, :through => :memberships, :source => "user",
           :conditions => "status = 1", :order => "last_name, first_name"
  belongs_to :owner, :class_name => "User", :foreign_key => "user_id"
  has_many :activities, :as => :owner, :conditions => ["owner_type = ?","Group"],
           :foreign_key => "item_id", :dependent => :destroy
  has_many :galleries, :as => :owner, :order => 'created_at DESC', :dependent => :destroy
  has_many :wall_comments, :as => :commentable, :order => 'created_at DESC',
                      :limit => NUM_WALL_COMMENTS, :dependent => :destroy
  has_many :news_items, :as => :newsable, :order => 'created_at desc', :dependent => :destroy
  has_many :events, :as => :eventable, :order => 'created_at desc', :dependent => :destroy
  has_many :forums, :as => :forumable, :order => 'created_at asc', :dependent => :destroy
  has_many :topics, :dependent => :destroy
  has_many :posts, :class_name => "ForumPost", :dependent => :destroy
  # shared entries
  has_many :shared_entries, :as => :destination, :order => 'created_at desc', :include => :entry
  has_many :public_google_docs, :through => :shared_entries, :source => 'entry', :conditions => 'google_doc = true AND public = true', :select => "*"
  # shared uploads
  has_many :shared_uploads, :as => :shared_uploadable, :order => 'created_at desc', :include => :upload
  has_many :uploads, :as => :uploadable, :order => 'created_at desc'
  # pages
  has_many :pages, :as => :contentable, :class_name => 'ContentPage', :order => 'created_at desc'

  before_create :create_blog
  after_create :create_forum
  after_create :log_activity
  before_update :set_old_description
  after_update :log_activity_description_changed
  
  is_indexed :fields => [ 'name', 'description' ]

  # GROUP modes
  PUBLIC = 0
  PRIVATE = 1
  HIDDEN = 2
  
  class << self

    # Return not hidden groups
    def not_hidden(page = 1)
      paginate(:all, :page => page,
                     :per_page => RASTER_PER_PAGE,
                     :conditions => ["mode = ? OR mode = ?", PUBLIC,PRIVATE],
                     :order => "name ASC")
    end
  end
  
  def recent_activity
    Activity.find_all_by_owner_id(self, :order => 'created_at DESC',
                                        :conditions => "owner_type = 'Group'",
                                         :limit => 10)
  end
  
  def public?
    self.mode == PUBLIC
  end
  
  def private?
    self.mode == PRIVATE
  end
  
  def hidden?
    self.mode == HIDDEN
  end
  
  def create_forum
    @forum = self.forums.build(:name => self.name,
      :description => "#{self.name}的討論串")
    @forum.save
  end
  
  def owner?(user)
    return false if user.nil?
    self.owner == user
  end
  
  def has_invited?(user)
    return false if user.nil?
    Membership.invited?(user,self)
  end
  
  def is_member?(user)
    return false if user.nil?
    users.include?(user) || self.owner == user
  end
  
  def feed_to
    [self] + self.users
  end
  
  ## Photo helpers
  def photo
    # This should only have one entry, but be paranoid.
    photos.find_all_by_avatar(true).first
  end

  # Return all the photos other than the primary one
  def other_photos
    photos.length > 1 ? photos - [photo] : []
  end

  def main_photo
    photo.nil? ? "group_default.jpg" : photo.public_filename(:avatar)
  end

  def thumb
    photo.nil? ? "t_group_default.jpg" : photo.public_filename(:thumb)
  end
  
  def small
    photo.nil? ? "no_picture.gif" : photo.public_filename(:small)
  end
  
  def tiny
    photo.nil? ? "group_default_thumb.jpg" : photo.public_filename(:tiny)
  end

  def icon
    photo.nil? ? "group_default_icon.jpg" : photo.public_filename(:icon)
  end

  def bounded_icon
    photo.nil? ? "group_default_icon.jpg" : photo.public_filename(:bounded_icon)
  end

  # Return the photos ordered by primary first, then by created_at.
  # They are already ordered by created_at as per the has_many association.
  def sorted_photos
    # The call to partition ensures that the primary photo comes first.
    # photos.partition(&:primary) => [[primary], [other one, another one]]
    # flatten yields [primary, other one, another one]
    @sorted_photos ||= photos.partition(&:primary).flatten
  end
  
  def to_param
    url_key || id
  end

  def default_role= val
    write_attribute(:default_role, val.to_s)
  end

  def default_role
    read_attribute(:default_role).to_sym
  end
  
  def is_content_visible? user
    return true if self.mode > Group::PRIVATE 
    return false if user == :false || user.nil?
    user.admin? || self.is_member?(user) || self.owner?(user) || self.has_invited?(user)
  end
  
  def can_edit?(user)
    return false if user.nil?
    check_user(user) || users.in_role(:manager).include?(user)
  end

  def can_participate?(user)
    return false if user == :false
    user.has_role?('Administrator') || check_user(user) || !users.find(:all, :conditions => "user_id = #{user.id} AND role != 'banned' AND role != 'observer'").empty?
  end
  
  def to_xml(options = {})
    options[:only] ||= []
    options[:only] << :name << :description << :news << :office << :email << :address << :city << :website << :url_key << :created_at
    options[:only] << :default_role << :mode
    super
  end
  
  private
  
  def set_old_description
    @old_description = Group.find(self).description
  end

  def log_activity_description_changed
    unless @old_description == description or description.blank?
      add_activities(:item => self, :owner => self)
    end
  end
  
  def log_activity
    if not self.hidden?
      activity = Activity.create!(:item => self, :owner => User.find(self.user_id))
      add_activities(:activity => activity, :owner => User.find(self.user_id))
    end
  end
  
end
