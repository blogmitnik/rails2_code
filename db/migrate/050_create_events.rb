class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.string :title, :null => false
      t.string :description
      t.references :user, :null => false
      t.datetime :start_time, :null => false
      t.datetime :end_time
      t.boolean :reminder
      t.integer :event_attendees_count, :default => 0
      t.integer :privacy, :null => false
      t.string :summary
      t.string :location
      t.text :uri
      t.integer :eventable_id
      t.string :eventable_type
      t.string :sponsor
      t.string :phone
      t.string :email
      t.string :city
      t.string :address

      t.timestamps
    end
    add_index "events", ["user_id"], :name => "index_events_on_user_id"
    add_index "events", ["eventable_id"], :name => "index_events_on_eventable_id"
  end

  def self.down
    drop_table :events
  end
end
