# == Schema Information
# Schema version: 32
#
# Table name: forums
#
#  id           :integer(11)     not null, primary key
#  name         :string(255)
#  description  :text
#  created_at   :datetime
#  updated_at   :datetime
#  topics_count :integer(11)     default(0), not null
#

class Forum < ActiveRecord::Base
  MAX_TITLE = SMALL_STRING_LENGTH
  MAX_BODY  = MAX_TEXT_LENGTH
  
  belongs_to :forumable, :polymorphic => true
  
  has_many :moderatorships, :dependent => :delete_all
  has_many :moderators, :through => :moderatorships, :source => :user
  
  has_many :topics, :order => "created_at DESC", :dependent => :destroy
  has_one  :recent_topic, :class_name => 'Topic', :order => 'sticky desc, replied_at desc'
  
  # this is used to see if a forum is "fresh"... we can't use topics because it puts
  # stickies first even if they are not the most recently modified
  has_many :recent_topics, :class_name => 'Topic', :order => 'replied_at DESC'
  has_one  :recent_topic,  :class_name => 'Topic', :order => 'replied_at DESC'
  
  has_many :posts, :order => "#{ForumPost.table_name}.created_at DESC", :dependent => :delete_all, 
           :class_name => 'ForumPost'
  has_one  :recent_post, :order => "#{ForumPost.table_name}.created_at DESC", 
           :class_name => 'ForumPost'
  
  has_permalink :name, :url_key, :scope => :forumable_id
  acts_as_list
  
  validates_presence_of :name
  validates_length_of :name, :maximum => MAX_TITLE, :message => "名稱不可超過65個字"
  validates_length_of :description, :maximum => MAX_BODY, :message => "內容不可超過1000個字"
  
  format_attribute :description
  
  named_scope :by_newest, :order => "created_at DESC"
  named_scope :recent, lambda { { :conditions => ['created_at > ?', 1.week.ago] } }
  named_scope :by_position, :order => "position ASC"
  named_scope :site_forums, :conditions => ["forumable_type='Site'"] 
  named_scope :group_forums, :conditions => ["forumable_type='Group'"] 
  
  def to_param
    url_key || id
  end
  
end
