class Widget < ActiveRecord::Base

    has_many :news_items, :as => :newsable, :order => 'created_at desc'
end
