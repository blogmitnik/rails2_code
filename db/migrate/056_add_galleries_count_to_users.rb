class AddGalleriesCountToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :galleries_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :users, :galleries_count
  end
end
