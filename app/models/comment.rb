# == Schema Information
# Schema version: 32
#
# Table name: comments
#
#  id          :integer(11)     not null, primary key
#  entry_id    :integer(11)
#  user_id     :integer(11)
#  guest_name  :string(255)
#  guest_email :string(255)
#  guest_url   :string(255)
#  body        :text
#  created_at  :datetime
#

class Comment < ActiveRecord::Base
  include ActivityLogger
  extend PreferencesHelper
  
  belongs_to :entry, :counter_cache => true
  belongs_to :user
  
  has_many :activities, :foreign_key => "item_id",
                        :conditions => "item_type = 'Comment'",
                        :dependent => :destroy
  
  BODY_MIN_LENGTH = 5
  BODY_MAX_LENGTH = 1000
  BODY_RANGE = BODY_MIN_LENGTH..BODY_MAX_LENGTH
  
  BODY_ROWS = 5
  BODY_COLS = 50
  
  validates_presence_of :body, :message => "回覆內容不可為空白"
  validates_length_of :body, :maximum => BODY_MAX_LENGTH, :message => "回覆內容最多不可超過1000個字"
  validates_uniqueness_of :body, :scope => [:entry_id, :user_id]

  after_create :log_activity, :send_receipt_reminder
  
  def after_create
    self.user.update_attribute(:last_activity, "在 #{entry.user.f} 的網誌文章發表了回覆")
    self.user.update_attribute(:last_activity_at, Time.now)
  end

  def to_liquid
    CommentDrop.new(self)
  end
  
  def duplicate?
    c = Comment.find_by_entry_id_and_user_id_and_body(entry, user_id, body)
    self.id = c.id unless c.nil?
    not c.nil?
  end
  
  private
  
  def log_activity
    activity = Activity.create!(:item => self, :owner => User.find(self.user_id))
    add_activities(:activity => activity, :owner => User.find(self.user_id))
  end
  
  def send_receipt_reminder
    return if self.user == self.entry.user
      @send_mail ||= Comment.global_prefs.email_notifications? &&
                     self.entry.user.entry_comment_notifications?
      Notifier.deliver_entry_comment_notification(self) if @send_mail
  end
end
