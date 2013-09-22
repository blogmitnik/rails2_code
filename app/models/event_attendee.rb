class EventAttendee < ActiveRecord::Base
  include ActivityLogger
  
  belongs_to :user
  belongs_to :event, :counter_cache => true
  has_many :activities, :foreign_key => "item_id", :dependent => :destroy,
                        :conditions => "item_type = 'EventAttendee'"
  validates_uniqueness_of :user_id, :scope => :event_id
  validates_presence_of :user_id, :event_id
  
  after_create :log_activity
  
  named_scope :current_events_for, lambda { |*args| { :include => [:event],
                                                      :conditions => ["events.start_time > Now() AND event_attendees.user_id = ?", (args.first.id)]} }

  def log_activity
    add_activities(:item => self, :owner => self.user)
  end
  
end
