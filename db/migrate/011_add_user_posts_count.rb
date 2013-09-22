class AddUserPostsCount < ActiveRecord::Migration
  def self.up
    add_column :users, :forum_posts_count, :integer, :null => false, :default => 0
    add_column :users, :site_forum_posts_count, :integer, :null => false, :default => 0
    add_column :users, :group_forum_posts_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :users, :forum_posts_count
    remove_column :users, :site_forum_posts_count
    remove_column :users, :group_forum_posts_count
  end
end
