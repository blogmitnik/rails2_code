class AddWindowsLiveLoginToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :wll_uid, :string, :unique => true
    add_column :users, :wll_name, :string
    add_index :users, :wll_uid
  end

  def self.down
    remove_column :users, :wll_uid
    remove_column :users, :wll_name
  end
end
