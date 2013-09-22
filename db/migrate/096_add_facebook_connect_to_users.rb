class AddFacebookConnectToUsers < ActiveRecord::Migration
  def self.up
     add_column :users, :fb_uid, :integer, :default => 0
     add_column :users, :email_hash, :string, :limit => 64, :null => true
     add_column :users, :fb_user_uid, :integer, :default => 0
     add_column :users, :fb_access_token, :string
  end

  def self.down
    remove_column :users, :fb_uid
    remove_column :users, :email_hash
    remove_column :users, :fb_user_uid
    remove_column :users, :fb_access_token
  end
end
