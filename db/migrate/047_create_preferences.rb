class CreatePreferences < ActiveRecord::Migration
  def self.up
    create_table :preferences do |t|
      t.string :domain, :null => false, :default => ""
      t.string :smtp_server, :null => false, :default => ""
      t.string :server_name
      t.string :app_name
      t.boolean :email_notifications, :null => false, :default => false
      t.boolean :email_verifications, :null => false, :default => false
      t.boolean :demo, :default => false
      t.text :analytics
      t.text :about
      t.boolean :graph_api, :null => false, :default => true

      t.timestamps
    end
    Preference.create!
  end

  def self.down
    drop_table :preferences
  end
end
