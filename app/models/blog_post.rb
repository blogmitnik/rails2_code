class BlogPost < Post
  
  MAX_TITLE = SMALL_STRING_LENGTH
  MAX_BODY  = MAX_TEXT_LENGTH
  
  attr_accessible :title, :body
  acts_as_taggable_on :tags
  
  belongs_to :blog
  belongs_to :user, :counter_cache => true
  has_many :wall_comments, :as => :commentable, :order => "created_at DESC",
                           :dependent => :destroy
                           
  format_attribute :body
  
  validates_presence_of :title, :message => "請輸入文章標題"
  validates_presence_of :body, :message => "請輸入文章內容"
  validates_length_of :title, :maximum => MAX_TITLE, 
                              :message => "文章標題不可超過65個字"
  
  after_create :log_activity
  
  def after_save
    case self.blog.owner.class.to_s
    when "User"
      self.user.update_attribute(:last_activity, "發佈了一篇日記")
      self.user.update_attribute(:last_activity_at, Time.now)
    when "Group"
      self.user.update_attribute(:last_activity, "在#{self.blog.owner.name}發佈了一篇日記")
      self.user.update_attribute(:last_activity_at, Time.now)
    end
  end
  
  private
  
    def log_activity
      add_activities(:item => self, :owner => blog.owner)
    end
end
