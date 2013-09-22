class CreateRolesUsersJoin < ActiveRecord::Migration
  def self.up
    create_table :roles_users, :id => false do |t|
      t.column :role_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
    end
    
    admin_user = User.create(:username => 'Admin', 
                             :email => 'mitnik@y7mail.com',
                             :description => 'Site Administrator',
                             :password => 'admin123', 
                             :password_confirmation => 'admin123')
    admin_role = Role.find_by_name('Administrator')
    admin_user.roles << admin_role
  end

  def self.down
    drop_table :roles_users
    User.find_by_username('Admin').destroy
  end
end