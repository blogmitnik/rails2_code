class AddGMapToEntries < ActiveRecord::Migration
  def self.up
    add_column :entries, :geo_lat, :float
    add_column :entries, :geo_long, :float
    add_column :entries, :show_geo, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :entries, :geo_lat
    remove_column :entries, :geo_long
    remove_column :entries, :show_geo
  end
end
