class ModifyGalleriesForPolymorphic < ActiveRecord::Migration
  def self.up
    add_column :galleries, :owner_id, :integer
    add_column :galleries, :owner_type, :string
    Gallery.find(:all).each do |gallery|
      gallery.owner_id = gallery.user_id
      gallery.owner_type = "User"
      gallery.save!
    end
    remove_column :galleries, :user_id
  end

  def self.down
    add_column :galleries, :user_id, :integer
    Gallery.find(:all).each do |gallery|
      gallery.user_id = gallery.owner_id
      gallery.save!
    end
    remove_column :galleries, :owner_id
    remove_column :galleries, :owner_type
  end
end
