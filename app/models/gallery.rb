class Gallery < ActiveRecord::Base

  MAX_TITLE_LENGTH = 65
  MAX_DESCRIPTION_LENGTH = 1000
  PRIVACY = { :public => 1, :friends => 2, :me => 3 }
  
  attr_accessible :title, :description, :location, :privacy
  belongs_to :owner, :polymorphic => true, :counter_cache => true
  belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
  has_many :wall_comments, :as => :commentable, :order => 'created_at DESC', :dependent => :destroy
  has_many :photos, :dependent => :destroy, :order => :position
  has_many :activities, :foreign_key => "item_id", :dependent => :destroy,
                        :conditions => "item_type = 'Gallery'"

  validates_length_of :title, :maximum => MAX_TITLE_LENGTH, :allow_nil => false
  validates_length_of :description, :maximum => MAX_DESCRIPTION_LENGTH, :allow_nil => true
  validates_length_of :location, :maximum => MAX_DESCRIPTION_LENGTH, :allow_nil => true
  validates_presence_of :owner_id
  validates_presence_of :privacy, :message => "請為這個相簿設定瀏覽權限"

  before_create :handle_nil_description

  
  def self.per_page
    6
  end
  
  def primary_photo
    photos.find_all_by_primary(true).first
  end
  
  def primary_photo=(photo)
    if photo.nil?
      self.primary_photo_id = nil
    else
      self.primary_photo_id = photo.id
    end
  end
  
  def primary_photo_url
    primary_photo.nil? ? "default.png" : primary_photo.public_filename
  end
  
  def avatar_url
    primary_photo.nil? ? "n_silhouette.gif" :
                         primary_photo.public_filename(:avatar)
  end

  def thumb_url
    primary_photo.nil? ? "s_default.jpg" :
                          primary_photo.public_filename(:thumb)
  end
  
  def small_url
    primary_photo.nil? ? "no_picture.gif" :
                         primary_photo.public_filename(:small)
  end
  
  def tiny_url
    primary_photo.nil? ? "t_silhouette.gif" :
                         primary_photo.public_filename(:tiny)
  end

  def icon_url
    primary_photo.nil? ? "bounded_icon.jpg" :
                         primary_photo.public_filename(:icon)
  end

  def bounded_icon_url
    primary_photo.nil? ? "bounded_icon.jpg" :
                         primary_photo.public_filename(:bounded_icon)
  end
    
  def short_description
    description[0..124]
  end
  
  def only_friends?
    self.privacy == PRIVACY[:friends]
  end
  
  def only_me?
    self.privacy == PRIVACY[:me]
  end

  protected

    def handle_nil_description
      self.description = "" if description.nil?
    end
    
    def log_activity
      activity = Activity.create!(:item => self, :owner => owner)
      add_activities(:activity => activity, :owner => owner)
    end
end
