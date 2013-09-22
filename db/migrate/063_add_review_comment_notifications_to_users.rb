class AddReviewCommentNotificationsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :entry_comment_notifications, :boolean, :default => true
  end

  def self.down
    remove_column :users, :entry_comment_notifications
  end
end
