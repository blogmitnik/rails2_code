class CreateGalleries < ActiveRecord::Migration
  def self.up
    create_table :galleries do |t|
      t.integer :user_id
      t.string :title
      t.string :location
      t.string :description
      t.integer :photos_count, :null => false, :default => 0
      t.integer :primary_picture_id
      t.integer :privacy, :null => false, :default => 1
      t.timestamps
    end
  end

  def self.down
    drop_table :galleries
  end
end
