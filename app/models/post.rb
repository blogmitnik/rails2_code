# == Schema Information
# Schema version: 32
#
# Table name: posts
#
#  id         :integer(11)     not null, primary key
#  topic_id   :integer(11)
#  user_id    :integer(11)
#  body       :text
#  created_at :datetime
#  updated_at :datetime
#

class Post < ActiveRecord::Base
  include ActivityLogger

  has_many :activities, :foreign_key => "item_id", :dependent => :destroy,
                        :conditions => "item_type = 'Post'"
  validates_presence_of :body, :user
  attr_accessible nil
end
