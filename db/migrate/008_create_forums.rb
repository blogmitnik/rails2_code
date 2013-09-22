class CreateForums < ActiveRecord::Migration
  def self.up
    create_table :forums do |t|
      t.string :name, :string
      t.text :description
      t.datetime :created_at
      t.datetime :updated_at
      t.string :url_key
      t.string :forumable_type
      t.integer :forumable_id
      t.integer :position
      t.integer :forum_posts_count, :default => 0
      t.integer :topics_count, :default => 0
      t.text :description_html
    end
    add_index "forums", ["url_key"], :name => "index_forums_on_url_key"
  end

  def self.down
    drop_table :forums
  end
end
