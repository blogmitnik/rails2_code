class SharedEntry < ActiveRecord::Base
    
  has_many :wall_comments, :as => :commentable, :dependent => :destroy, :order => 'created_at desc'
  belongs_to :shared_by, :class_name => 'User', :foreign_key => 'shared_by_id'
  belongs_to :entry
  belongs_to :destination, :polymorphic => true

end
