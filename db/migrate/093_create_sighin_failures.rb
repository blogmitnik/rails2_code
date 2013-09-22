class CreateSighinFailures < ActiveRecord::Migration
  def self.up
    create_table "signin_failures", :force => true do |t|
      t.column "email",      :string
      t.column "ip",         :string
      t.column "created_at", :datetime
    end
  end

  def self.down
    drop_table :signin_failures
  end
end
