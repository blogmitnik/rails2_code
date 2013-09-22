class AddBlogPostsCountTousers < ActiveRecord::Migration
  def self.up
    add_column :users, :blog_posts_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :users, :blog_posts_count
  end
end
