# == Schema Information
# Schema version: 32
#
# Table name: categories
#
#  id   :integer(11)     not null, primary key
#  name :string(255)
#

class Category < ActiveRecord::Base
  has_many :articles, :dependent => :nullify
  
  validates_length_of :name, :maximum => 80
end
