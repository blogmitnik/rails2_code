class CreateNewsItems < ActiveRecord::Migration
  def self.up
    create_table :news_items do |t|
      t.string   "title"
      t.text     "body"
      t.integer  "newsable_id"
      t.string   "newsable_type"
      t.string   "url_key"
      t.string   "icon"
      t.integer  "creator_id"
      
      t.timestamps
    end
    add_index "news_items", ["url_key"], :name => "index_news_items_on_url_key"
  end

  def self.down
    drop_table :news_items
  end
end
