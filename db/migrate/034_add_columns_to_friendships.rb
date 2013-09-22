class AddColumnsToFriendships < ActiveRecord::Migration
  def self.up
    add_column :friendships, :status, :string
    add_column :friendships, :created_at, :datetime
    add_column :friendships, :accepted_at, :datetime
  end

  def self.down
    remove_column :friendships, :status
    remove_column :friendships, :created_at
    remove_column :friendships, :accepted_at
  end
end
