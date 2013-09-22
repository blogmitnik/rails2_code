class AddGroupCommentNotificationToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :group_comment_notifications, :boolean, :default => true
    add_column :users, :news_comment_notifications, :boolean, :default => true
  end

  def self.down
    remove_column :users, :group_comment_notifications
    remove_column :users, :news_comment_notifications
  end
end
