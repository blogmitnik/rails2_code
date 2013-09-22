class CreateSharedEntries < ActiveRecord::Migration
  def self.up
    create_table "shared_entries", :force => true do |t|
      t.integer  "shared_by_id"
      t.integer  "entry_id"
      t.string   "destination_type", :default => "",    :null => false
      t.integer  "destination_id",                      :null => false
      t.boolean  "can_edit",         :default => false
      t.boolean  "public",           :default => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :shared_entries
  end
end
