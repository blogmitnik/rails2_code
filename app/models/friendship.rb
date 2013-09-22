# == Schema Information
# Schema version: 32
#
# Table name: friendships
#
#  id               :integer(11)     not null, primary key
#  user_id          :integer(11)     not null
#  friend_id        :integer(11)     not null
#  xfn_friend       :boolean(1)      not null
#  xfn_acquaintance :boolean(1)      not null
#  xfn_contact      :boolean(1)      not null
#  xfn_met          :boolean(1)      not null
#  xfn_coworker     :boolean(1)      not null
#  xfn_colleague    :boolean(1)      not null
#  xfn_coresident   :boolean(1)      not null
#  xfn_neighbor     :boolean(1)      not null
#  xfn_child        :boolean(1)      not null
#  xfn_parent       :boolean(1)      not null
#  xfn_sibling      :boolean(1)      not null
#  xfn_spouse       :boolean(1)      not null
#  xfn_kin          :boolean(1)      not null
#  xfn_muse         :boolean(1)      not null
#  xfn_crush        :boolean(1)      not null
#  xfn_date         :boolean(1)      not null
#  xfn_sweetheart   :boolean(1)      not null
#

class Friendship < ActiveRecord::Base
  extend ActivityLogger
  extend PreferencesHelper
  
  belongs_to :user
  belongs_to :friend, :class_name => 'User', :foreign_key => 'friend_id'
  has_many :activities, :foreign_key => "item_id", :dependent => :destroy,
                        :conditions => "item_type = 'Friendship'"
  validates_presence_of :user_id, :friend_id
  
  def xfn_friendship=(friendship_type)
    self.xfn_friend = false
    self.xfn_acquaintance = false
    self.xfn_contact = false
    case friendship_type
    when 'xfn_friend' : self.xfn_friend = true
    when 'xfn_acquaintance' : self.xfn_acquaintance = true
    when 'xfn_contact' : self.xfn_contact = true
    end
  end
  
  def xfn_friendship
    return 'xfn_friend' if self.xfn_friend == true
    return 'xfn_acquaintance' if self.xfn_acquaintance == true
    return 'xfn_contact' if self.xfn_contact == true
    false
  end

  def xfn_geographical=(geo_type)
    self.xfn_coresident = false
    self.xfn_neighbor = false
    case geo_type
    when 'xfn_coresident' : self.xfn_coresident = true
    when 'xfn_neighbor' : self.xfn_neighbor = true
    end
  end

  def xfn_geographical
    return 'xfn_coresident' if self.xfn_coresident
    return 'xfn_neighbor' if self.xfn_neighbor
    false
  end
  
  def xfn_family=(family_type)
    self.xfn_child = false
    self.xfn_parent = false
    self.xfn_sibling = false
    self.xfn_spouse = false
    self.xfn_kin = false
    case family_type
    when 'xfn_child' : self.xfn_child = true
    when 'xfn_parent' : self.xfn_parent = true
    when 'xfn_sibling' : self.xfn_sibling = true
    when 'xfn_spouse' : self.xfn_spouse = true
    when 'xfn_kin' : self.xfn_kin = true
    end
  end
  
  def xfn_family
    return 'xfn_child' if self.xfn_child
    return 'xfn_parent' if self.xfn_parent
    return 'xfn_sibling' if self.xfn_sibling
    return 'xfn_spouse' if self.xfn_spouse
    return 'xfn_kin' if self.xfn_kin
    false
  end
  
  ACCEPTED  = 'accepted'
  REQUESTED = 'requested'
  PENDING   = 'pending'
  
  def accept
    Friendship.accept(user_id, friend_id)
  end
  
  def breakup
    Friendship.breakup(user_id, friend_id)
  end

  class << self
  
    def exists?(user, friend)
      not conn(user, friend).nil?
    end
    
    alias exist? exists?
  
    def request(user, friend, send_mail = nil)
      if send_mail.nil?
        send_mail = !global_prefs.nil? && global_prefs.email_notifications? && friend.connection_notifications?
      end
      if user == friend or Friendship.exists?(user, friend)
        nil
      elsif
        transaction do
          create(:user => user, :friend => friend, :status => 'pending')
          create(:user => friend, :friend => user, :status => 'requested')
        end
        if send_mail
          connection = conn(friend, user)
          Notifier.deliver_connection_request(connection)
        end
        true
      end
    end
  
    def accept(user, friend)
      transaction do
        accepted_at = Time.now
        accept_one_side(user, friend, accepted_at)
        accept_one_side(friend, user, accepted_at)
      end
      unless [user, friend].include?(User.find_first_admin)
        log_activity(conn(user, friend))
      end
    end
    
    def connect(user, friend, send_mail = nil)
      transaction do
        request(user, friend, send_mail)
        accept(user, friend)
      end
      conn(user, friend)
    end
  
    def breakup(user, friend)
      transaction do
        destroy(conn(user, friend))
        destroy(conn(friend, user))
      end
    end
  
    def conn(user, friend)
      find_by_user_id_and_friend_id(user, friend)
    end

    def accepted?(user, friend)
      conn(user, friend).status == "accepted"
    end
    
    def connected?(user, friend)
      exist?(user, friend) and accepted?(user, friend)
    end
    
    def pending?(user, friend)
      exist?(user, friend) and conn(user, friend).status == "pending"
    end
  end
  
  def after_update
    if self.user.friends.include?(friend)
      self.user.update_attribute(:last_activity, "和 #{friend.name} 成為了朋友")
      self.user.update_attribute(:last_activity_at, Time.now)
    else
      self.user.update_attribute(:last_activity, "修改了和 #{friend.name} 之間的關係")
      self.user.update_attribute(:last_activity_at, Time.now)
    end
  end
  
  private
  
  class << self
    def accept_one_side(user, friend, accepted_at)
      conn = conn(user, friend)
      conn.update_attributes!(:status => 'accepted',
                              :accepted_at => accepted_at)
    end
    
    def log_activity(conn)
      activity = Activity.create!(:item => conn, :owner => conn.user)
      add_activities(:activity => activity, :owner => conn.user)
      add_activities(:activity => activity, :owner => conn.friend)
    end
  end
  
end
