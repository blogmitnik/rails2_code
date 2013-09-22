class ModifyPhotosForPolymorphic < ActiveRecord::Migration
  def self.up
    add_column :photos, :owner_id, :integer
    add_column :photos, :owner_type, :string
    Photo.find(:all).each do |photo|
      photo.owner_id = photo.user_id
      photo.owner_type = "User"
      photo.save!
    end
    remove_column :photos, :user_id
  end

  def self.down
    add_column :photos, :user_id, :integer
    Gallery.find(:all).each do |photo|
      photo.user_id = photo.owner_id
      photo.save!
    end
    remove_column :photos, :owner_id
    remove_column :photos, :owner_type
  end
end
