class CreateBagPropertyEnums < ActiveRecord::Migration
  def self.up
    create_table "bag_property_enums", :force => true do |t|
      t.integer "bag_property_id"
      t.string  "name"
      t.string  "value"
      t.integer "sort"
      
      t.timestamps
    end
    add_index "bag_property_enums", ["bag_property_id"], :name => "index_bag_property_enums_on_bag_property_id"
  end

  def self.down
    drop_table :bag_property_enums
  end
end
