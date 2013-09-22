class AddReActivationCodeToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :reactivation_code, :string, :limit => 40
    add_column :users, :reactivated_at, :datetime
  end

  def self.down
    remove_column :users, :reactivation_code
    remove_column :users, :reactivated_at
  end
end
