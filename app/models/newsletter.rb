# == Schema Information
# Schema version: 32
#
# Table name: newsletters
#
#  id         :integer(11)     not null, primary key
#  subject    :string(255)
#  body       :text
#  sent       :boolean(1)      not null
#  created_at :datetime
#  updated_at :datetime
#

class Newsletter < ActiveRecord::Base
  extend PreferencesHelper
  
  validates_presence_of :subject, :body
  validates_length_of :subject, :maximum => 255
   validates_length_of :body, :maximum => 10000
end
