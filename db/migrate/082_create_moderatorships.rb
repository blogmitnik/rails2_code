class CreateModeratorships < ActiveRecord::Migration
  def self.up
    create_table :moderatorships do |t|
	   t.integer "forum_id"
	   t.integer "user_id"
      t.timestamps
    end
    add_index "moderatorships", ["forum_id"], :name => "index_moderatorships_on_forum_id"
  end

  def self.down
    drop_table :moderatorships
  end
end
