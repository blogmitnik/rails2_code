class Activity < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
  belongs_to :item, :polymorphic => true
  has_many :feeds, :dependent => :destroy
  
  GLOBAL_FEED_SIZE = 10

  # This is especially useful for sites that require email verifications.
  # Their 'connected with admin' item won't show up until they verify.
  def self.global_feed
    find(:all, 
         :joins => "INNER JOIN users p ON activities.owner_id = p.id",
         :conditions => [%(p.enabled = ? AND 
                           p.activation_code IS NULL AND 
                           p.activated_at IS NOT NULL AND 
                           p.reactivation_code IS NULL), 
                         true], 
         :order => 'activities.created_at DESC',
         :limit => GLOBAL_FEED_SIZE)
  end
end
