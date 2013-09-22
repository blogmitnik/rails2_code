# == Schema Information
# Schema version: 32
#
# Table name: topics
#
#  id          :integer(11)     not null, primary key
#  forum_id    :integer(11)
#  user_id     :integer(11)
#  name        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  posts_count :integer(11)     default(0), not null
#

class Topic < ActiveRecord::Base
  include ActivityLogger
  NUM_RECENT = 6
  
  belongs_to :forum, :counter_cache => true
  belongs_to :user
  belongs_to :group
  belongs_to :last_post, :class_name => "ForumPost", :foreign_key => 'last_post_id'
  has_many :posts, :order => "#{ForumPost.table_name}.created_at", :dependent => :delete_all, 
                   :class_name => "ForumPost"
  has_one  :recent_post, :order => "#{ForumPost.table_name}.created_at DESC", :class_name => "ForumPost"
  
  has_many :monitorships
  has_many :monitors, :through => :monitorships, :conditions => ["#{Monitorship.table_name}.active = ?", true], :source => :user
  
  has_many :voices, :through => :posts, :source => :user, :uniq => true
  belongs_to :replied_by_user, :foreign_key => "replied_by", :class_name => "User"

  has_many :activities, :foreign_key => "item_id", :dependent => :destroy,
                        :conditions => "item_type = 'Topic'"
  
  validates_presence_of :title
  validates_length_of :title, :maximum => 255
  
  before_create { |r| r.group_id = r.forum.forumable_id }
  after_create   :log_activity
  before_create  :set_default_replied_at_and_sticky
  before_update  :check_for_changing_forums
  after_save     :update_forum_counter_cache
  before_destroy :update_post_user_counts
  after_destroy  :update_forum_counter_cache
  
  attr_accessible :title
  # to help with the create form
  attr_accessor :body
	
  def hit!
    self.class.increment_counter :hits, id
  end

  def sticky?() sticky == 1 end

  def views() hits end

  def paged?() forum_posts_count > ForumPost.per_page end
  
  def last_page
    [(forum_posts_count.to_f / ForumPost.per_page).ceil.to_i, 1].max
  end

  def editable_by?(user)
    case self.forum.forumable.class.to_s
    when "Group"
      user && (user.id == user_id || user.admin? || user.moderator_of?(forum_id) || self.forum.forumable.can_edit?(user))
    else
      user && (user.id == user_id || user.admin? || user.moderator_of?(forum_id))
    end
  end
  
  def update_cached_post_fields(post)
    # these fields are not accessible to mass assignment
    remaining_post = post.frozen? ? recent_post : post
    if remaining_post
      self.class.update_all(['replied_at = ?, replied_by = ?, last_post_id = ?, forum_posts_count = ?', 
        remaining_post.created_at, remaining_post.user_id, remaining_post.id, posts.count], ['id = ?', id])
    else
      self.destroy
    end
  end
  
  def self.find_recent
    find(:all, :order => "created_at DESC", :limit => NUM_RECENT)
  end
  
  protected
    def set_default_replied_at_and_sticky
      self.replied_at = Time.now.utc
      self.sticky ||= 0
    end

    def set_post_forum_id
      ForumPost.update_all ['forum_id = ?', forum_id], ['topic_id = ?', id]
    end

    def check_for_changing_forums
      old = Topic.find(id)
      @old_forum_id = old.forum_id if old.forum_id != forum_id
      true
    end
    
    # using count isn't ideal but it gives us correct caches each time
    def update_forum_counter_cache
      forum_conditions = ['topics_count = ?', Topic.count(:id, :conditions => {:forum_id => forum_id})]
      # if the topic moved forums
      if !frozen? && @old_forum_id && @old_forum_id != forum_id
        set_post_forum_id
        Forum.update_all ['topics_count = ?, forum_posts_count = ?', 
          Topic.count(:id, :conditions => {:forum_id => @old_forum_id}),
          ForumPost.count(:id, :conditions => {:forum_id => @old_forum_id})], ['id = ?', @old_forum_id]
      end
      # if the topic moved forums or was deleted
      if frozen? || (@old_forum_id && @old_forum_id != forum_id)
        forum_conditions.first << ", forum_posts_count = ?"
        forum_conditions << ForumPost.count(:id, :conditions => {:forum_id => forum_id})
      end
      Forum.update_all forum_conditions, ['id = ?', forum_id]
      @old_forum_id = @voices = nil
    end
    
    def update_post_user_counts
      @voices = voices.to_a
    end
  
  private
  
    def log_activity
      if self.forum.forumable.class.to_s == "Group"
        add_activities(:item => self, :owner => self.forum.forumable, :owner_type => "Group")
      else
        add_activities(:item => self, :owner => user)
      end
    end
end
