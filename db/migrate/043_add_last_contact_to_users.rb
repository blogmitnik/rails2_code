class AddLastContactToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :last_contacted_at, :datetime
    add_column :users, :connection_notifications, :boolean, :default => true
    add_column :users, :message_notifications, :boolean, :default => true
    add_column :users, :wall_comment_notifications, :boolean, :default => true
    add_column :users, :blog_comment_notifications, :boolean, :default => true
  end

  def self.down
    remove_column :users, :last_contacted_at
    remove_column :users, :connection_notifications
    remove_column :users, :message_notifications
    remove_column :users, :wall_comment_notifications
    remove_column :users, :blog_comment_notifications
  end
end
