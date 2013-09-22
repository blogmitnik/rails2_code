class AddIconToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :icon, :string
    add_column :events, :photos_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :events, :icon
    remove_column :events, :photos_count
  end
end
