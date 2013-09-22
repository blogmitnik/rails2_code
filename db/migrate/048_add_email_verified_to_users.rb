class AddEmailVerifiedToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :email_verified, :boolean, :default => nil
    if Preference.find(:first).email_verifications?
      # This is to modify the database for the splitting between
      # 'deactivated' and 'email_verified'.
      User.find(:all).each do |user|
        user.email_verified = user.enabled?
        user.save
      end
    end rescue nil
  end

  def self.down
    remove_column :users, :email_verified
  end
end
