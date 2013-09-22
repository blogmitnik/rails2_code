class AddCreatorToGalleryAndPhoto < ActiveRecord::Migration
  def self.up
    add_column :galleries, :creator_id, :integer
    add_column :photos, :creator_id, :integer
  end

  def self.down
    remove_column :galleries, :creator_id
    remove_column :photos, :creator_id
  end
end
