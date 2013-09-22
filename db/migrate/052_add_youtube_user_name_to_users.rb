class AddYoutubeUserNameToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :youtube_username, :string, :unique => true
  end

  def self.down
    remove_column :users, :youtube_username
  end
end
