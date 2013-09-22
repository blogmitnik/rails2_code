class CreateBagPropertyValues < ActiveRecord::Migration
  def self.up
    create_table "bag_property_values", :force => true do |t|
      t.integer  "data_type",                                :default => 1
      t.integer  "user_id"
      t.integer  "bag_property_id"
      t.string   "svalue"
      t.text     "tvalue",               :limit => 16777215
      t.integer  "ivalue"
      t.integer  "bag_property_enum_id"
      t.datetime "tsvalue"
      t.integer  "visibility"
      
      t.timestamps
    end
    add_index "bag_property_values", ["user_id", "bag_property_id"], :name => "index_bag_property_values_on_user_id_and_bag_property_id"
  end

  def self.down
    drop_table :bag_property_values
  end
end
