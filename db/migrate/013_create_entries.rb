class CreateEntries < ActiveRecord::Migration
  def self.up
    create_table :entries do |t|
      t.integer :user_id
      t.string :title
      t.text :body
      t.string :permalink, :limit => 2083
      t.boolean :google_doc, :default => false
      t.boolean :displayable, :default => false
      t.datetime :published_at
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :wall_comments_count, :null => false, :default => 0
    end
    add_index :entries, :user_id
  end

  def self.down
    drop_table :entries
  end
end