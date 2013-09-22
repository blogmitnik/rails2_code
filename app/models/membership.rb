class Membership < ActiveRecord::Base
  extend ActivityLogger
  extend PreferencesHelper
  
  belongs_to :group
  belongs_to :user
  has_many :activities, :foreign_key => "item_id", :dependent => :destroy
  validates_presence_of :user_id, :group_id
  
  # Status codes.
  ACCEPTED  = 0
  INVITED   = 1
  PENDING   = 2
  
  # Accept a membership request (instance method).
  def accept
    Membership.accept(user_id, group_id)
  end
  
  def breakup
    Membership.breakup(user_id, group_id)
  end
  
  # roles can be defined as symbols.  We want to store them as strings in the database
  def role= val
    write_attribute(:role, val.to_s)
  end

  def role
    read_attribute(:role).to_sym
  end
  
  class << self
    
    # Return true if the person is member of the group.
    def exists?(user, group)
      not mem(user, group).nil?
    end
    
    alias exist? exists?
    
    # Make a pending membership request.
    def request(user, group, send_mail = nil)
      if send_mail.nil?
        send_mail = global_prefs.email_notifications? &&
                    group.owner.connection_notifications?
      end
      if user.groups.include?(group) or Membership.exists?(user, group)
        nil
      else
        if group.public? or group.private?
          transaction do
            create(:user => user, :group => group, :status => PENDING)
            if send_mail
              membership = user.memberships.find(:first, :conditions => ['group_id = ?',group])
              Notifier.deliver_membership_request(membership)
            end
          end
          if group.public?
            membership = user.memberships.find(:first, :conditions => ['group_id = ?',group])
            membership.accept
            if send_mail
              Notifier.deliver_membership_public_group(membership)
            end
          end
        end
        true
      end
    end
    
    def invite(user, group, send_mail = nil)
      if send_mail.nil?
        send_mail = global_prefs.email_notifications? &&
                    group.owner.connection_notifications?
      end
      if user.groups.include?(group) or Membership.exists?(user, group)
        nil
      else
        transaction do
          create(:user => user, :group => group, :status => INVITED)
          if send_mail
            membership = user.memberships.find(:first, :conditions => ['group_id = ?',group])
            Notifier.deliver_invitation_notification(membership)
          end
        end
        true
      end
    end
    
    # Accept a membership request.
    def accept(user, group)
      transaction do
        accepted_at = Time.now
        accept_one_side(user, group, accepted_at)
      end
      unless Group.find(group).hidden?
        log_activity(mem(user, group))
      end
    end
    
    def breakup(user, group)
      transaction do
        destroy(mem(user, group))
      end
    end
    
    def mem(user, group)
      find_by_user_id_and_group_id(user, group)
    end
    
    def accepted?(user, group)
      exist?(user, group) and mem(user, group).status == ACCEPTED
    end
    
    def connected?(user, group)
      exist?(user, group) and accepted?(user, group)
    end
    
    def pending?(user, group)
      exist?(user, group) and mem(user,group).status == PENDING
    end
    
    def invited?(user, group)
      exist?(user, group) and mem(user,group).status == INVITED
    end
    
  end
  
  private
  
  class << self
    # Update the db with one side of an accepted connection request.
    def accept_one_side(user, group, accepted_at)
      mem = mem(user, group)
      mem.update_attributes!(:status => ACCEPTED,
                             :accepted_at => accepted_at, 
                             :role => "member")
    end
  
    def log_activity(membership)
      activity = Activity.create!(:item => membership, :owner => membership.user)
      add_activities(:activity => activity, :owner => membership.user)
      activity = Activity.create!(:item => membership, :owner => membership.group)
      add_activities(:activity => activity, :owner => membership.group)
    end
  end
  
end
