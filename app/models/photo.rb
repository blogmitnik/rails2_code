# == Schema Information
# Schema version: 32
#
# Table name: photos
#
#  id           :integer(11)     not null, primary key
#  user_id      :integer(11)
#  title        :string(255)
#  body         :text
#  created_at   :datetime
#  content_type :string(100)
#  filename     :string(255)
#  path         :string(255)
#  parent_id    :integer(11)
#  thumbnail    :string(255)
#  size         :integer(11)
#  width        :integer(11)
#  height       :integer(11)
#  geo_lat      :float
#  geo_long     :float
#  show_geo     :boolean(1)      default(TRUE), not null
#

class Photo < ActiveRecord::Base
  include ActivityLogger
  include SecureMethods
  UPLOAD_LIMIT = 5 # megabytes
  
  # attr_accessible is a nightmare with attachment_fu, so use
  # attr_protected instead.
  attr_protected :id, :parent_id, :created_at, :updated_at
  
  has_attachment :storage => :file_system, 
                          :resize_to => '640>', 
                          :thumbnails => { :avatar       => '200x200>',
                                           :thumb        => '160x120>',
                                           :small        => '75>', 
                                           :tiny         => '50',
                                           :icon         => '36>',
                                           :bounded_icon => '36x36>' }, 
                          :max_size => UPLOAD_LIMIT.megabytes,
                          :min_size => 1, 
                          :content_type => :image, 
                          :processor => 'Rmagick'

  belongs_to :owner, :polymorphic => true
  belongs_to :gallery, :counter_cache => true
  belongs_to :event, :counter_cache => true
  belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
  has_many :wall_comments, :as => :commentable, :order => 'created_at DESC', :dependent => :destroy
  
  acts_as_list :scope => :gallery_id
  has_many :activities, :foreign_key => "item_id",
                        :conditions => "item_type = 'Photo'",
                        :dependent => :destroy
  acts_as_taggable
  validates_as_attachment
  validates_presence_of :filename
  
  after_create :log_activity
    
  # Override the crappy default AttachmentFu error messages.
  def validate
    if filename.nil?
      errors.add_to_base("請選擇你要上傳的圖片檔案")
    else
      # Images should only be GIF, JPEG, or PNG
      enum = attachment_options[:content_type]
      unless enum.nil? || enum.include?(send(:content_type))
        errors.add_to_base("抱歉！你只能上傳 GIF, JPEG 或 PNG 格式的相片")
      end
      # Images should be less than UPLOAD_LIMIT MB.
      enum = attachment_options[:size]
      unless enum.nil? || enum.include?(send(:size))
        msg = "抱歉！上傳的相片檔案最大不可超過 #{UPLOAD_LIMIT} MB"
        errors.add_to_base(msg)
      end
    end
  end
  
  def can_edit?(user)
    return false if user.nil?
    check_user(user)
  end
  
  def label
    title.nil? ? "" : title
  end

  def label_from_filename
    File.basename(filename, File.extname(filename)).titleize
  end
  
  
  def log_activity
    activity = Activity.create!(:item => self, :owner => owner)
    add_activities(:activity => activity, :owner => owner)
  end
  
end
