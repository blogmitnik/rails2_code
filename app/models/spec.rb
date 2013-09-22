# == Schema Information
# Schema version: 32
#
# Table name: specs
#
#  id       :integer(11)     not null, primary key
#  user_id  :integer(11)     not null
#  activity :text
#  interest :text
#  music    :text
#  tv       :text
#  movie    :text
#  book     :text
#  maxim    :text
#  about_me :text
#

class Spec < ActiveRecord::Base
  belongs_to :user

  COMMON_ROWS = 6
  COMMON_COLS = 35
  
  validates_length_of :activity, :interest, :music, :tv, :movie, :book, :maxim, :about_me, :maximum => 1000

  def after_update
    self.user.update_attribute(:last_activity, "修改了個人資訊")
    self.user.update_attribute(:last_activity_at, Time.now)
  end
end
