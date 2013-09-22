class AddUsersDetail < ActiveRecord::Migration
  def self.up
    add_column :users, :first_name, :string, :null => false
    add_column :users, :middle_name, :string
    add_column :users, :last_name, :string, :null => false
    add_column :users, :full_name, :string
  end

  def self.down
    remove_column :users, :first_name
    remove_column :users, :middle_name
    remove_column :users, :last_name
    remove_column :users, :full_name
  end
end
