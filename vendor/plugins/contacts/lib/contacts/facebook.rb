require 'page_scraper'

class Contacts
  class Facebook < PageScraper
    URL                 = "http://www.facebook.com/"
    LOGIN_URL      = "http://m.facebook.com/"
    PROTOCOL_ERROR      = "Facebook has changed its protocols, please upgrade this library."
    
    def real_connect
     create_agent
     prepare
    end
    
    def prepare
      page = agent.get(LOGIN_URL)
      login_form = page.forms.first
      login_form.email = @login
      login_form.pass = @password
      page = agent.submit(login_form, login_form.buttons.first)
      raise AuthenticationError, "電郵地址或密碼有錯誤。" if page.body =~ /電郵地址或密碼有誤。/
      #Friends Page
      friends_links = page.links_with(:href => /\/friends.php/)
      friends_link = ''
      friends_links.each{ |flink| friends_link = flink.href if flink && flink.href && flink.text == 'Friends'}
      raise ConnectionError, PROTOCOL_ERROR unless friends_link
      friends_url = 'http://m.facebook.com' + friends_link
      page = agent.get(friends_url)
      #My Friends Page
      friends_link = page.links_with(:href => /\/friends.php/)
      @my_friends_link = ''
      friends_link.each{|f| @my_friends_link = f.href if f.text == '朋友'}
      @logout_url = page.link_with(:href => /logout/)
      return true
    end
    
    def contacts
     contacts = []
     next_page = true
     current_page = 2
     my_friends_url = 'http://m.facebook.com' + @my_friends_link
     page = agent.get(my_friends_url)
     raise AuthenticationError, "請先登入。" if page.body =~ /輸入帳號和密碼。/
     
     while(next_page)
      next_page = false
      data = page.search('//tr[@valign="top"]')
      if data
       data.each do |node|
        td_nodes = node.children
        if td_nodes
         childs = td_nodes[0]
         fr_name = childs.child.text
         fr_href = ''
         childs.children.each do |nd|
          if nd.name == 'small'
           nd.children.each do |n|
            fr_href = n.attributes['href'] if n.name == 'a' && n.text == '訊息'
           end
          end
         end
         contacts << [fr_name, fr_href.to_s] unless fr_href.blank?
        end
       end
      end # End Outer if
      data = page.search('//div[@class="pad"]')
    data.each do |node|
     childs = node.children
     next if childs.empty?
     childs.each do |c|
      if c.name == 'a' && c.text.to_i == current_page
       next_page = 'http://m.facebook.com' + c.attributes['href'].to_s
       break
      end
     end
    end
      current_page += 1
    page = agent.get(next_page) unless next_page == false
     end #End While
     return contacts
    end
    
    def send_message(contact, message, subj=nil)
     success = false
     if contact
      url_inbox = "http://m.facebook.com" + contact.last
      page = agent.get(url_inbox)
      raise AuthenticationError, "請先登入。" if page.body =~ /輸入帳號和密碼。/
      
      page.forms.each do |f|
 if f.has_field?('body')
   f.subject = subj if subj && !subj.empty?
      f.body = message
   page = agent.submit(f, f.buttons.first)
   return true if page.code == '200'
        end
      end
     end
     return success
    end
    
     def logout
      agent.click @logout_url if @logout_url
      return true
    end
    
  end

  TYPES[:facebook] = Facebook
end