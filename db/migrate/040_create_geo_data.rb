class CreateGeoData < ActiveRecord::Migration
  def self.up
    create_table :geo_data do |t|
      t.column :zipcode,  :string
      t.column :latitude,  :float
      t.column :longitude, :float
      t.column :city,      :string
      t.column :state,     :string
      t.column :address,   :string
    end
    add_index "geo_data", ["zipcode"], :name => "zip_code_optimization"
  end

  def self.down
    drop_table :geo_data
  end
end