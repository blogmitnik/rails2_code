class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.string :name
      t.text :description
      t.text :news
      t.string :office
      t.string :email
      t.string :address
      t.string :city
      t.string :website
      t.integer :mode, :null => false, :default => 0
      t.integer :user_id
      t.integer :avatar_id
      t.integer :forum_posts_count, :null => false, :default => 0

      t.timestamps
    end
    add_index "groups", ["user_id"], :name => "index_groups_on_user_id"
  end

  def self.down
    drop_table :groups
  end
end
