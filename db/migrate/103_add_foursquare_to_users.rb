class AddFoursquareToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :foursquare_uid, :integer, :default => 0
    add_column :users, :foursquare_token, :string
  end

  def self.down
    remove_column :users, :foursquare_uid
    remove_column :users, :foursquare_token
  end
end
