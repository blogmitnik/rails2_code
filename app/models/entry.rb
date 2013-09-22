# == Schema Information
# Schema version: 32
#
# Table name: entries
#
#  id             :integer(11)     not null, primary key
#  user_id        :integer(11)
#  title          :string(255)
#  body           :text
#  comments_count :integer(11)     default(0), not null
#  created_at     :datetime
#  updated_at     :datetime
#

class Entry < ActiveRecord::Base
  include ActivityLogger
  include GoogleDocs
  
  belongs_to :user, :counter_cache => true
  has_many :shared_entries
  has_many :wall_comments, :as => :commentable, :dependent => :destroy, :order => 'created_at desc'
  has_many :activities, :foreign_key => "item_id", :dependent => :destroy,
                        :conditions => "item_type = 'Entry'"
         
  validates_presence_of :title, :permalink

  def share_with_friend(sharer, friend_id, can_edit = false, show_on_profile = false)
    friend = User.find(friend_id)
    sharing_to_self = sharer.id == friend_id
    shared_entry = friend.shared_entries.build(:shared_by_id => sharer.id, :entry_id => self.id, 
    :can_edit => can_edit || sharing_to_self, :public => (show_on_profile == true && sharing_to_self))
    shared_entry.save!

  end

  def share_with_group(sharer, group_id)
    group = Group.find(group_id)
    if group.is_member?(sharer)
      shared_entry = group.shared_entries.build(:shared_by_id => sharer.id, :entry_id => self.id, :public => true)
      shared_entry.save!
    end

  end

  def permalink= val
    if val != nil
      if is_google_doc(val)
        self.google_doc = true
        self.displayable = is_published(val)
      end
    end
    write_attribute(:permalink, val)
  end

  def html
    get_html(self.permalink)
  end

  def google_doc_id
    get_doc_id(self.permalink)
  end

  def is_presentation
    PRESENTATION == get_document_type(self.permalink) 
  end

  def share_with_friends(user, friend_ids, can_edit, show_on_profile)
    friend_ids.each do |friend_id, checked|
      self.share_with_friend(user, friend_id, can_edit, show_on_profile) if (checked == "1")
    end    
  end

  def share_with_groups(user, group_ids)
    group_ids.each do |group_id, checked|
      self.share_with_group(user, group_id) if (checked == "1")
    end    
  end

end
