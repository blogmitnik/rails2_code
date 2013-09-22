class CreateSites < ActiveRecord::Migration
  def self.up
    create_table "sites", :force => true do |t|
      t.string   "name"
      t.string   "title",                    :default => "", :null => false
      t.string   "subtitle",                 :default => "", :null => false
      t.string   "slogan",                   :default => "", :null => false
      t.string   "background_color",         :default => "", :null => false
      t.string   "font_color",               :default => "", :null => false
      t.string   "font_style",               :default => "", :null => false
      t.string   "font_size",                :default => "", :null => false
      t.string   "content_background_color", :default => "", :null => false
      t.string   "a_font_style",             :default => "", :null => false
      t.string   "a_font_color",             :default => "", :null => false
      t.string   "top_background_color",     :default => "", :null => false
      t.string   "top_color",                :default => "", :null => false
      t.string   "link_button_background_color"
      t.string   "link_button_font_color"
      t.string   "highlight_color"
      
      t.timestamps
    end
  end

  def self.down
    drop_table :sites
  end
end
