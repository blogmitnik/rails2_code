class CreateWallComments < ActiveRecord::Migration
  def self.up
    create_table :wall_comments do |t|
      t.integer :commenter_id
      t.integer :commentable_id
      t.string  :commentable_type, :default => "", :null => false
      t.text    :body

      t.timestamps
    end
    add_index :wall_comments, :commenter_id
    add_index :wall_comments, [:commentable_id, :commentable_type]
  end

  def self.down
    drop_table :wall_comments
  end
end
