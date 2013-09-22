class CreateTopics < ActiveRecord::Migration
  def self.up
    create_table :topics do |t|
      t.integer :forum_id
      t.integer :user_id
      t.integer :group_id
      t.string :title
      t.integer :forum_posts_count, :default => 0
      t.integer :hits, :default => 0
      t.integer :sticky, :default => 0
      t.boolean :locked, :default => false
      t.datetime :replied_at
      t.integer :replied_by
      t.integer :last_post_id
      
      t.timestamps
    end
    add_index "topics", ["forum_id"], :name => "index_topics_on_forum_id"
    add_index "topics", ["forum_id", "sticky", "replied_at"], :name => "index_topics_on_sticky_and_replied_at"
    add_index "topics", ["forum_id", "replied_at"], :name => "index_topics_on_forum_id_and_replied_at"
  end

  def self.down
    drop_table :topics
  end
end
