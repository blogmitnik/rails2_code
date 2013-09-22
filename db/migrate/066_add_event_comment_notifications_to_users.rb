class AddEventCommentNotificationsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :event_comment_notifications, :boolean, :default => true
  end

  def self.down
    remove_column :users, :event_comment_notifications
  end
end
