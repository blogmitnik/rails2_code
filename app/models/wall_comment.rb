class WallComment < ActiveRecord::Base
  include ActivityLogger
  extend PreferencesHelper
  
  attr_accessor :commented_user, :send_mail
  
  belongs_to :commentable, :polymorphic => true, :counter_cache => true
  belongs_to :commenter, :class_name => "User",
                         :foreign_key => "commenter_id"

  belongs_to :user, :counter_cache => true
  belongs_to :photo, :counter_cache => true, :foreign_key => "photo_id"
  belongs_to :event, :counter_cache => true
  belongs_to :group, :counter_cache => true
  belongs_to :post
  belongs_to :news_item, :counter_cache => true
  
  has_many :activities, :foreign_key => "item_id",
                        :conditions => "item_type = 'WallComment'",
                        :dependent => :destroy
  
  BODY_MIN_LENGTH = 5
  BODY_MAX_LENGTH = 500
  BODY_RANGE = BODY_MIN_LENGTH..BODY_MAX_LENGTH
  
  WALL_BODY_MIN_LENGTH = 5
  WALL_BODY_MAX_LENGTH = 200
  WALL_BODY_RANGE = WALL_BODY_MIN_LENGTH..WALL_BODY_MAX_LENGTH
  
  BODY_ROWS = 3
  BODY_COLS = 50

  validates_presence_of :body, :commenter
  validates_length_of :body, :maximum => MEDIUM_TEXT_LENGTH
  validates_length_of :body, :maximum => MEDIUM_TEXT_LENGTH,
                             :if => :wall_comment?
  
  after_create :log_activity, :send_receipt_reminder
    
  # Return the person for the thing commented on.
  # For example, for blog post comments it's the blog's person
  # For wall comments, it's the person himself.
  def commented_user
    @commented_user ||= case commentable.class.to_s
                          when "User"
                            commentable
                          when "BlogPost"
                            if commentable.blog.owner_type == "User"
                              commentable.blog.owner
                            elsif commentable.blog.owner_type == "Group"
                              commentable.blog.owner.owner
                            end
                          when "Photo"
                            if commentable.owner_type == "User"
                              commentable.owner
                            elsif commentable.owner_type == "Group"
                              commentable.owner.owner
                            end
                          when "Event"
                            commentable.user
                          when "Group"
                            commentable.owner
                          when "NewsItem"
                            commentable.creator
                          end
  end
  
  def self.between_users user1, user2
    find(:all, {
      :order => 'created_at desc',
      :conditions => [
        "(commenter_id=? and commentable_id=?) or (commenter_id=? and commentable_id=?) and commentable_type='User'",
        user1.id, user2.id, user2.id, user1.id]
    })
  end
  
  def can_edit?(user)
    return true if self.commenter_id == user.id
    
    case self.commentable_type
    when 'User'
      return commentable_id == user.id
    when 'Photo'
      if commentable.owner_type == 'User'
        return commentable.owner_id == user.id
      elsif commentable.owner_type == 'Group'
        return commentable.owner.can_edit?(user)
      end
    when 'NewsItem'
      if commentable.newsable.is_a?(User)
        return self.commentable.newsable.id == user.id
      elsif commentable.newsable.is_a?(Group)
        return self.commentable.newsable.can_edit?(user)
      elsif commentable.newsable.is_a?(Widget) || commentable.newsable.is_a?(Site)
        return user.admin?
      else
        raise 'Unknow news item type:' + commentable.newsable.class
      end
    when 'Group'
      return self.commentable.can_edit?(user)
    when 'Event'
      return commentable.user_id == user.id
    when 'Post'
      if commentable.blog.owner_type == "User"
        return commentable.blog.owner_id == user.id
      elsif commentable.blog.owner_type == "Group"
        return commentable.blog.owner.can_edit?(user)
      end
    end
    return false
  end

  def after_create
    if wall_comment?
      self.commentable.update_attribute(:last_activity, "在 #{commented_user.name} 的塗鴉牆新增留言")
      self.commentable.update_attribute(:last_activity_at, Time.now)
    elsif photo_comment?
      if self.commentable.owner_type == "User"
      self.commentable.owner.update_attribute(:last_activity, "對 #{commented_user.name} 的圖片發表評論")
      self.commentable.owner.update_attribute(:last_activity_at, Time.now)
      elsif self.commentable.owner_type == "group"
      self.commentable.owner.owner.update_attribute(:last_activity, "對群組 #{commented_user.name} 的圖片發表評論")
      self.commentable.owner.owner.update_attribute(:last_activity_at, Time.now)
      end
    elsif event_comment?
      self.commentable.user.update_attribute(:last_activity, "在 #{commented_user.name} 建立的活動新增留言")
      self.commentable.user.update_attribute(:last_activity_at, Time.now)
    end
  end

  
  private
    
    def wall_comment?
      commentable.class.to_s == "User"
    end
    
    def blog_post_comment?
      commentable.class.to_s == "BlogPost"
    end
  
    def photo_comment?
      commentable.class.to_s == "Photo"
    end
    
    def event_comment?
      commentable.class.to_s == "Event"
    end
    
    def group_comment?
      commentable.class.to_s == "Group"
    end
    
    def news_comment?
      commentable.class.to_s == "NewsItem"
    end
    
    def notifications?
      if wall_comment?
        commented_user.wall_comment_notifications?
      elsif blog_post_comment?
        commented_user.blog_comment_notifications?
      elsif photo_comment?
        commented_user.photo_comment_notifications?
      elsif event_comment?
        commented_user.event_comment_notifications?
      elsif group_comment?
        commented_user.group_comment_notifications?
      elsif news_comment?
        commented_user.news_comment_notifications?
      end
    end
    
    def log_activity
      unless self.commentable.class.to_s == "Group" and self.commentable.hidden?
        activity = Activity.create!(:item => self, :owner => commenter)
        add_activities(:activity => activity, :owner => commenter)
        unless commented_user.nil? or commenter == commented_user
          add_activities(:activity => activity, :owner => commented_user,
                         :include_user => true)
        end
      end
    end

    def send_receipt_reminder
      return if commenter == commented_user
      if wall_comment?
        @send_mail ||= WallComment.global_prefs.email_notifications? &&
                       commented_user.wall_comment_notifications?
        Notifier.deliver_wall_comment_notification(self) if @send_mail
      elsif blog_post_comment?
        @send_mail ||= WallComment.global_prefs.email_notifications? &&
                       commented_user.blog_comment_notifications?
        if self.commentable.blog.owner_type == "User"
          Notifier.deliver_blog_comment_notification(self) if @send_mail
        elsif self.commentable.blog.owner_type == "Group"
          Notifier.deliver_group_blog_comment_notification(self) if @send_mail
        end
      elsif photo_comment?
        @send_mail ||= WallComment.global_prefs.email_notifications? &&
                       commented_user.photo_comment_notifications?
        if self.commentable.owner_type == "User"
          Notifier.deliver_photo_comment_notification(self) if @send_mail
        elsif self.commentable.owner_type == "Group"
          Notifier.deliver_group_photo_comment_notification(self) if @send_mail
        end
      elsif event_comment?
        @send_mail ||= WallComment.global_prefs.email_notifications? &&
                       commented_user.event_comment_notifications?
        Notifier.deliver_event_comment_notification(self) if @send_mail
      elsif group_comment?
        @send_mail ||= WallComment.global_prefs.email_notifications? &&
                       commented_user.group_comment_notifications?
        Notifier.deliver_group_comment_notification(self) if @send_mail
      elsif news_comment?
        @send_mail ||= WallComment.global_prefs.email_notifications? &&
                       commented_user.news_comment_notifications?
        if self.commentable.newsable_type == "Group"
          Notifier.deliver_group_news_comment_notification(self) if @send_mail
        elsif self.commentable.newsable_type == "Widget"
          Notifier.deliver_member_story_comment_notification(self) if @send_mail
        end
      end
    end
end
