class NewsItem < ActiveRecord::Base
  include ActivityLogger
  include SecureMethods

  has_permalink :title, :url_key

  acts_as_taggable_on :tags

  belongs_to :newsable, :polymorphic => true
  belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'   

  has_many :wall_comments, :as => :commentable, :order => 'created_at DESC', :dependent => :destroy
  has_many :photos, :as => :photoable, :order => 'created_at desc'
  has_many :activities, :foreign_key => "item_id", 
           :conditions => "item_type = 'NewsItem'", 
           :order => 'created_at desc', :dependent => :destroy  

  validates_presence_of :title, :body

  file_column :icon, :magick => {
    :versions => { 
      :bigger => {:crop => "1:1", :size => "200x200>", :name => "bigger"},
      :big => {:crop => "1:1", :size => "150x150>", :name => "big"},
      :medium => {:crop => "1:1", :size => "100x100>", :name => "medium"},
      :small => {:crop => "1:1", :size => "75x75>", :name => "small"},
      :tiny => {:crop => "1:1", :size => "50x50>", :name => "tiny"}
    }
  }

  before_save :whitelist_attributes
  after_create :log_activity

  def to_param
    url_key || id
  end

  def self.latest_news_from(rolename = 'Administrator', limit = 5)
    role = Role.find(:first, :include => 'users', :conditions => ["name = ?", rolename])
    if role && role.users.length > 0
      user_ids = role.users.collect{|u| u.id}.join(',')
      NewsItem.find(:all, :conditions => "newsable_type = 'User' AND newsable_id IN (#{user_ids})", :limit => limit, :order => 'created_at desc')
    else
      NewsItem.find(:all , :limit => limit, :order => 'created_at desc')
    end
  end

  def can_edit?(user)
    check_creator(user)
  end
  
  def video
    ""
  end
  
  def video= url
    if !url.empty?
      body << ('[youtube: ' + url +']') if /^http:\/\/www.youtube/.match( url )
      body << ('[googlevideo: ' + url +']') if /^http:\/\/video.google/.match( url )
    end
  end

  protected
  
  def whitelist_attributes
    # let admins throw in whatever they want TODO decide if this is a good or bad idea
    #if !self.creator.admin?
      self.title = white_list(self.title)
      self.body = white_list(self.body)
    #end
  end
  
  private
  
    def log_activity
      activity = Activity.create!(:item => self, :owner => newsable)
      add_activities(:activity => activity, :owner => newsable)
    end
  
end
