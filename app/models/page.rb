# == Schema Information
# Schema version: 32
#
# Table name: pages
#
#  id         :integer(11)     not null, primary key
#  title      :string(255)
#  permalink  :string(255)
#  body       :text
#  created_at :datetime
#  updated_at :datetime
#

class Page < ActiveRecord::Base
  validates_presence_of :title, :body
  validates_length_of :title, :within => 3..255
  validates_length_of :body, :maximum => 10000
  
  def to_param
     "#{id}-#{permalink}"
  end
  
  def before_create
    @attributes['permalink'] = 
      title.downcase.gsub(/\s+/, '_').gsub(/[^a-zA-Z0-9_]+/, '')
  end
   
end
