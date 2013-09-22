class AddWallCommentsCount < ActiveRecord::Migration
  def self.up
    add_column :users, :wall_comments_count, :integer, :null => false, :default => 0
    add_column :groups, :wall_comments_count, :integer, :null => false, :default => 0
    add_column :events, :wall_comments_count, :integer, :null => false, :default => 0
    add_column :posts, :wall_comments_count, :integer, :null => false, :default => 0
    add_column :photos, :wall_comments_count, :integer, :null => false, :default => 0
    add_column :news_items, :wall_comments_count, :integer, :null => false, :default => 0
    add_column :galleries, :wall_comments_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :users, :wall_comments_count
    remove_column :groups, :wall_comments_count
    remove_column :events, :wall_comments_count
    remove_column :posts, :wall_comments_count
    remove_column :photos, :wall_comments_count
    remove_column :news_items, :wall_comments_count
    remove_column :galleries, :wall_comments_count
  end
end
