# == Schema Information
# Schema version: 32
#
# Table name: usertemplates
#
#  id      :integer(11)     not null, primary key
#  user_id :integer(11)
#  name    :string(255)
#  body    :text
#

class Usertemplate < ActiveRecord::Base
  belongs_to :user
  validates_length_of :body, :maximum => 10000
end
