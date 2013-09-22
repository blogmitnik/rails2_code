class CreateContacts < ActiveRecord::Migration
  def self.up
    create_table :contacts do |t|
      t.column :user_id, :integer, :null => false
	   t.column :network, :string
	
      t.column :gender, :string
      t.column :show_gender, :boolean, :default => true
      t.column :birthday, :date
      t.column :show_birthday, :boolean, :default => true
      t.column :hometown, :string
      t.column :affection, :string
      t.column :polity, :string
      t.column :religion, :string

	   t.column :msn_account, :string
      t.column :ichat_account, :string
      t.column :gtalk_account, :string
      t.column :aim_account, :string
      t.column :phone, :string
      t.column :cell_phone, :string
      t.column :address, :string
      t.column :city, :string
      t.column :zipcode, :integer
	   t.column :state, :string
      t.column :website, :text
	
      t.column :school, :string
      t.column :school_year, :string
      t.column :dept, :string
      t.column :major, :string
      t.column :high_school, :string
      t.column :high_school_year, :string
      t.column :employer, :string
      t.column :position, :string
      t.column :brief, :string
      t.column :country, :string
      t.column :is_working, :boolean, :default => true
    end
    add_index :contacts, :user_id
  end

  def self.down
    drop_table :contacts
  end
end
