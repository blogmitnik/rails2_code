class StatusUpdate < ActiveRecord::Base
  include ActivityLogger
  
  validates_presence_of :user
  belongs_to :user
  has_many :wall_comments, :as => :commentable, :dependent => :destroy, :order => 'created_at DESC'  
  has_many :activities, :foreign_key => "item_id", 
           :conditions => "item_type = 'StatusUpdate'", 
           :order => 'created_at desc', :dependent => :destroy    
  named_scope :recent, :order => 'created_at DESC'
  
  after_create :log_activity
  
  validates_presence_of :text
  
  def can_edit?(user)
    user.id == self.user_id || admin?
  end
  
  private
  
    def log_activity
      activity = Activity.create!(:item => self, :owner => self.user)
      add_activities(:activity => activity, :owner => self.user)
    end
  
end
