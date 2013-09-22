class CreatePosts < ActiveRecord::Migration
  def self.up
    create_table :posts do |t|
      t.integer :topic_id
      t.integer :user_id
      t.integer :group_id
      t.text :body
      t.integer :forum_id
      t.text :body_html
      t.datetime :created_at
      t.datetime :updated_at
    end
    add_index "posts", ["topic_id", "created_at"], :name => "index_posts_on_topic_id"
    add_index "posts", ["forum_id", "created_at"], :name => "index_posts_on_forum_id"
    add_index "posts", ["user_id", "created_at"], :name => "index_posts_on_user_id"
    add_index "posts", ["group_id", "created_at"], :name => "index_posts_on_group_id"
  end

  def self.down
    drop_table :posts
  end
end
