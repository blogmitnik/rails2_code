class CreateSpecs < ActiveRecord::Migration
  def self.up
    create_table :specs do |t|
      t.column :user_id, :integer, :null => false
      t.column :activity, :text
      t.column :interest, :text
      t.column :music, :text
      t.column :tv, :text
      t.column :movie, :text
      t.column :book, :text
      t.column :maxim, :text
      t.column :about_me, :text
    end
    add_index :specs, :user_id
  end

  def self.down
    drop_table :specs
  end
end
