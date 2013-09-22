class CreateSharedUploads < ActiveRecord::Migration
  def self.up
    create_table "shared_uploads", :force => true do |t|
      t.integer  "shared_uploadable_id"
      t.string   "shared_uploadable_type"
      t.integer  "upload_id"
      t.integer  "shared_by_id"
      
      t.timestamps
    end
    add_index "shared_uploads", ["shared_uploadable_id"], :name => "index_shared_uploads_on_uploadable_id"
    add_index "shared_uploads", ["upload_id"], :name => "index_shared_uploads_on_upload_id"
    add_index "shared_uploads", ["shared_by_id"], :name => "index_shared_uploads_on_shared_by_id"
  end

  def self.down
    drop_table :shared_uploads
  end
end
