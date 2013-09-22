class Event < ActiveRecord::Base
  include ActivityLogger
  
  acts_as_taggable_on :tags
  
  MAX_DESCRIPTION_LENGTH = 1000
  MAX_TITLE_LENGTH = 65
  PRIVACY = { :public => 1, :friends => 2 }
  EMAIL_REGEX = /\A[A-Z0-9\._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}\z/i

  belongs_to :user
  belongs_to :eventable, :polymorphic => true
  has_many :event_attendees
  has_many :attendees, :through => :event_attendees, :source => :user, :dependent => :destroy
  has_many :wall_comments, :as => :commentable, :order => 'created_at DESC', :dependent => :destroy
  has_many :activities, :foreign_key => "item_id", :dependent => :destroy,
                        :conditions => "item_type = 'Event'"
  has_many :photos, :as => :owner, :dependent => :destroy, :order => "created_at"
  has_many :galleries, :as => :owner, :order => 'created_at DESC', :dependent => :destroy
  
  validates_presence_of :title, :start_time, :sponsor, :location, :user_id, :eventable_id
  validates_length_of :title, :maximum => MAX_TITLE_LENGTH
  validates_length_of :description, :maximum => MAX_DESCRIPTION_LENGTH, :allow_blank => true
  validates_format_of :email, :with => EMAIL_REGEX, :message => "請輸入正確的Email地址格式", :allow_blank => true
  validates_numericality_of :phone, :message => "電話號碼只能包含阿拉伯數字", :allow_blank => true

  is_indexed :fields => [ 'title', 'description', 'summary', 'location' ]
  
  file_column :icon, :magick => {
    :versions => { 
      :bigger => {:crop => "1:1", :size => "200x200>", :name => "bigger"},
      :big => {:crop => "1:1", :size => "150x150>", :name => "big"},
      :medium => {:crop => "1:1", :size => "100x100>", :name => "medium"},
      :small => {:crop => "1:1", :size => "75x75>", :name => "small"},
      :tiny => {:crop => "1:1", :size => "50x50>", :name => "tiny"}
    }
  }
  
  # named_scopes
  named_scope :recent, :order => 'created_at DESC'
  named_scope :user_events, 
              lambda { |user| { :conditions => ["user_id = ? OR (privacy = ? OR (privacy = ? AND (user_id IN (?))))", 
                                                  user.id,
                                                  PRIVACY[:public], 
                                                  PRIVACY[:friends], 
                                                  user.friends] } }

  named_scope :period_events,
              lambda { |date_from, date_until| { :conditions => ['start_time >= ? and start_time <= ?',
                                                 date_from, date_until] } }

  after_create :log_activity
  
  def self.monthly_events(date)
    self.period_events(date.beginning_of_month, date.to_time.end_of_month)
  end
  
  def self.daily_events(date)
    self.period_events(date.beginning_of_day, date.to_time.end_of_day)
  end

  def validate
    if end_time
      unless start_time <= end_time
        errors.add("活動事件的開始時間必須在結束時間之前")
      end
    end
  end
  
  def attend(user)
    self.event_attendees.create!(:user => user)
  rescue ActiveRecord::RecordInvalid
    nil
  end

  def unattend(user)
    if event_attendee = self.event_attendees.find_by_user_id(user)
        event_attendee.destroy
    else
      nil
    end
  end

  def attending?(user)
    self.attendee_ids.include?(user[:id])
  end

  def only_friends?
    self.privacy == PRIVACY[:friends]
  end
  
  def uri= val
    write_attribute(:uri, fix_http(val))
  end
  
  protected
  
  def fix_http str
    return '' if str.blank?
    str.starts_with?('http') ? str : "http://#{str}"
  end
  
  private

    def log_activity
      add_activities(:item => self, :owner => self.user)
    end
  
end
