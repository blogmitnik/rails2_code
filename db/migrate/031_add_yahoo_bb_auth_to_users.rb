class AddYahooBbAuthToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :yahoo_userhash, :string
  end

  def self.down
    remove_column :users, :yahoo_userhash
  end
end
