class SharedUpload < ActiveRecord::Base

  include SecureMethods

  has_many :wall_comments, :as => :commentable, :dependent => :destroy, :order => 'created_at ASC'
  belongs_to :upload
  belongs_to :shared_uploadable, :polymorphic => true
  belongs_to :shared_by, :class_name => 'User', :foreign_key => 'shared_by_id'

  validates_presence_of :shared_uploadable_id, :upload_id, :shared_by_id

  def after_create
    activity = Activity.create!(:item => self, :owner => shared_uploadable)
    if shared_uploadable.is_a?(Group) && shared_uploadable.respond_to?(:feed_to)
      add_activities(:activity => activity, :owner => shared_uploadable, :owner_type => "Group")
    elsif shared_uploadable.is_a?(User)
      add_activities(:activity => activity, :owner => shared_uploadable)
    end
  end

  def can_edit?(user)
    shared_uploadable.id == user.id || check_sharer(user)
  end

end
