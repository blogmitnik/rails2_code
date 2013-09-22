class CreateEcategories < ActiveRecord::Migration
  def self.up
    create_table :ecategories do |t|
      t.column :name, :string
    end
    news_ecategory = Ecategory.create(:name => '藝術與攝影')
    news_ecategory = Ecategory.create(:name => '汽車與機車')
    news_ecategory = Ecategory.create(:name => '夢境與超自然')
    news_ecategory = Ecategory.create(:name => '時尚, 流行與購物')
    news_ecategory = Ecategory.create(:name => '美食與餐廳')
    news_ecategory = Ecategory.create(:name => '朋友, 玩伴')
    news_ecategory = Ecategory.create(:name => '遊戲, 玩樂')
    news_ecategory = Ecategory.create(:name => '點子, 計畫, 夢想')
    news_ecategory = Ecategory.create(:name => '工作, 生涯, 事業')
    news_ecategory = Ecategory.create(:name => '生活相關')
    news_ecategory = Ecategory.create(:name => '電影, 電視, 影視')
    news_ecategory = Ecategory.create(:name => '音樂, MV, 廣播')
    news_ecategory = Ecategory.create(:name => '新聞與政治')
    news_ecategory = Ecategory.create(:name => '派對, 夜生活')
    news_ecategory = Ecategory.create(:name => '寵物與動物')
    news_ecategory = Ecategory.create(:name => '測驗, 考查, 調查')
    news_ecategory = Ecategory.create(:name => '宗教信仰, 哲學觀')
    news_ecategory = Ecategory.create(:name => '約會, 社交, 關係')
    news_ecategory = Ecategory.create(:name => '大學, 校園生活')
    news_ecategory = Ecategory.create(:name => '戶外, 運動')
    news_ecategory = Ecategory.create(:name => '旅遊, 城市, 國家')
    news_ecategory = Ecategory.create(:name => 'Web, HTML, 技術')
    news_ecategory = Ecategory.create(:name => '寫作, 詩歌, 詞曲')
    news_ecategory = Ecategory.create(:name => '一般網誌文章')
    change_column :entries, :ecategory_id, :integer, :default => news_ecategory
  end

  def self.down
    change_column :entries, :ecategory_id, :integer, :default => 0
    drop_table :ecategories
  end
end
