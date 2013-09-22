class AddExtraColumnsToEntries < ActiveRecord::Migration
  def self.up
    add_column :entries, :ecategory_id, :integer, :null => true
    add_column :entries, :mood, :string, :null => true
    add_column :entries, :disable_comment, :boolean, :default => false
  end

  def self.down
    remove_column :entries, :ecategory_id
    remove_column :entries, :mood
    remove_column :entries, :disable_comment
  end
end
