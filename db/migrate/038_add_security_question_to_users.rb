class AddSecurityQuestionToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :question, :string
    add_column :users, :answer, :string
  end

  def self.down
    remove_column :users, :question
    remove_column :users, :answer
  end
end
