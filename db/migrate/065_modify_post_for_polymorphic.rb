class ModifyPostForPolymorphic < ActiveRecord::Migration
  def self.up
    add_column :posts, :blog_id, :integer
    add_column :posts, :title, :string
    add_column :posts, :type, :string
    Post.find(:all).each do |post|
      post.type = "ForumPost"
      post.save!
    end
  end

  def self.down
    remove_column :posts, :blog_id, :integer
    remove_column :posts, :title, :string
    remove_column :posts, :type, :string
  end
end
