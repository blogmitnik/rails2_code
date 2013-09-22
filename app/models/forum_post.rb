class ForumPost < Post
  def self.per_page() 30 end
  
  is_indexed :fields => [ 'body' ],
             :conditions => "type = 'ForumPost'",
             :include => [{:association_name => 'topic', :field => 'title'}]
  
  belongs_to :forum, :counter_cache => true
  belongs_to :topic, :counter_cache => true
  belongs_to :user, :counter_cache => true
  belongs_to :group, :counter_cache => true
  
  format_attribute :body
  before_create { |r| r.forum_id = r.topic.forum_id }
  before_create { |r| r.group_id = r.topic.forum.forumable_id }
  after_create  :update_cached_fields
  after_destroy :update_cached_fields
  
  validates_presence_of :body, :user
  attr_accessible :body
  
  after_create :log_activity
  
  def editable_by?(user)
    case self.forum.forumable.class.to_s
    when "Group"
      user && (user.id == user_id || user.admin? || user.moderator_of?(forum_id) || self.forum.forumable.can_edit?(user))
    else
      user && (user.id == user_id || user.admin? || user.moderator_of?(forum_id))
    end
  end
  
  def to_xml(options = {})
    options[:except] ||= []
    options[:except] << :topic_title << :forum_name
    super
  end
  
  def after_save
    self.user.update_attribute(:last_activity, "發表了一篇討論文章")
    self.user.update_attribute(:last_activity_at, Time.now)
  end
  
  protected
  # using count isn't ideal but it gives us correct caches each time
  def update_cached_fields
    Forum.update_all ['forum_posts_count = ?', ForumPost.count(:id, :conditions => {:forum_id => forum_id})], ['id = ?', forum_id]
    topic.update_cached_post_fields(self)
    User.update_posts_count(user_id)
    if self.forum.forumable_type == "Site"
      User.update_site_posts_count(user_id)
    elsif self.forum.forumable_type == "Group"
      User.update_group_posts_count(user_id)
    end
  end
    
  private
  
    def blog?
      type == "BlogPost"
    end
    
    def forum?
      type == "ForumPost"
    end
  
    def log_activity
      if self.forum.forumable.class.to_s == "Group"
        add_activities(:item => self, :owner => self.forum.forumable, :owner_type => "Group")
      else
        add_activities(:item => self, :owner => user)
      end
    end
end