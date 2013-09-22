class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :username, :limit => 64, :null => false
      t.string :email, :limit => 50, :null => false
      t.string :hashed_password, :limit => 40
      t.boolean :enabled, :default => true, :null => false
      t.text :description
      t.datetime :last_login_at
      t.integer :signin_count, :default => 0
    end
    add_index :users, :username
  end

  def self.down
    drop_table :users
  end
end
