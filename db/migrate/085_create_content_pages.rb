class CreateContentPages < ActiveRecord::Migration
  def self.up
    create_table "content_pages", :force => true do |t|
      t.integer  "creator_id"
      t.string   "title"
      t.string   "url_key"
      t.text     "body"
      t.string   "locale"
      t.text     "body_raw"
      t.integer  "contentable_id"
      t.string   "contentable_type"
      t.integer  "parent_id", :default => 0, :null => false
      t.integer  "version"
      
      t.timestamps
    end
    add_index "content_pages", ["parent_id"], :name => "index_content_pages_on_parent_id"
  end

  def self.down
    drop_table :content_pages
  end
end
