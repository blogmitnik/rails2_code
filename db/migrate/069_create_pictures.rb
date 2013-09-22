class CreatePictures < ActiveRecord::Migration
  def self.up
    create_table :pictures do |t|
      t.string   "caption",        :limit => 1000
      t.integer  "photoable_id"
      t.string   "image"
      t.string   "photoable_type"
      t.integer  "creator_id"

      t.timestamps
    end
    add_index "pictures", ["photoable_id"], :name => "index_photos_on_user_id"
  end

  def self.down
    drop_table :pictures
  end
end
