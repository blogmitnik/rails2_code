class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.column :name, :string
    end
    news_category = Category.create(:name => '網站訊息')
    change_column :articles, :category_id, :integer, :default => news_category
  end

  def self.down
    change_column :articles, :category_id, :integer, :default => 0
    drop_table :categories
  end
end
