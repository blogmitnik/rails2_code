module NewsHelper

  def news_item_link(link_text, news_item)
    case news_item.newsable
    when User
      link_to(link_text, profile_note_path(news_item.newsable, news_item))
    when Site
      link_to(link_text, news_path(news_item))
    when Group
      link_to(link_text, group_news_path(news_item.newsable, news_item))
    when Widget
      link_to(link_text, member_story_path(news_item))
    else
      news_item.title  
    end
  end

end
