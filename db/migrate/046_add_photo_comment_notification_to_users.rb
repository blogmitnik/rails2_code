class AddPhotoCommentNotificationToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :photo_comment_notifications, :boolean, :default => true
  end

  def self.down
    remove_column :users, :photo_comment_notifications
  end
end
