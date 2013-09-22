class AddGalleriesCountToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :galleries_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :groups, :galleries_count
  end
end
