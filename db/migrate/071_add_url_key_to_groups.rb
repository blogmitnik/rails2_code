class AddUrlKeyToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :url_key, :string
    add_column :groups, :default_role, :string, :default => "member"
  end

  def self.down
    remove_column :groups, :url_key
    remove_column :groups, :default_role
  end
end
