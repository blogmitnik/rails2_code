class AddRoleToMemberships < ActiveRecord::Migration
  def self.up
    add_column :memberships, :role, :string
    add_column :memberships, :banned, :boolean, :default => false
  end

  def self.down
    remove_column :memberships, :role
    remove_column :memberships, :banned
  end
end
