class ContentPageVersions < ActiveRecord::Migration
  def self.up
    create_table "content_page_versions", :force => true do |t|
      t.integer  "content_page_id"
      t.integer  "version"
      t.integer  "creator_id"
      t.string   "title"
      t.string   "url_key"
      t.text     "body"
      t.string   "locale"
      t.datetime "updated_at"
      t.text     "body_raw"
      t.integer  "contentable_id"
      t.string   "contentable_type"
      t.integer  "parent_id", :default => 0
    end
  end

  def self.down
    drop_table :content_page_versions
  end
end
