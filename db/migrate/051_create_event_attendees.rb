class CreateEventAttendees < ActiveRecord::Migration
  def self.up
    create_table :event_attendees do |t|
      t.references :user
      t.references :event
    end
  end

  def self.down
    drop_table :event_attendees
  end
end
