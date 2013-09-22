class Site < ActiveRecord::Base

  has_many :news_items, :as => :newsable
  has_many :pages, :as => :contentable, :class_name => 'ContentPage'
  has_many :uploads, :as => :uploadable
  has_one :logo, :dependent => :destroy 
  
end