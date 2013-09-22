class AddTwitterOauthToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :twitter_id, :bigint
    add_column :users, :screen_name, :string
    add_column :users, :token, :string
    add_column :users, :secret, :string
    add_column :users, :profile_image_url, :string
    add_index :users, :twitter_id
    add_index :users, :screen_name
  end

  def self.down
    remove_column :users, :twitter_id
    remove_column :users, :token
    remove_column :users, :secret
    remove_column :users, :profile_image_url
  end
end
