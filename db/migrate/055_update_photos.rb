class UpdatePhotos < ActiveRecord::Migration
  def self.up
    add_column :photos, :avatar, :boolean
    add_column :photos, :gallery_id, :integer
    add_column :photos, :position, :integer
    add_column :photos, :updated_at, :datetime
    add_column :photos, :primary, :boolean
  end

  def self.down
    remove_column :photos, :position
    remove_column :photos, :gallery_id
    remove_column :photos, :avatar
    remove_column :photos, :updated_at
    remove_column :photos, :primary
  end
end
