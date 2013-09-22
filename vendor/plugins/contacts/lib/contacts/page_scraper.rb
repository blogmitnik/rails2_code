require 'mechanize'

class Contacts
 class PageScraper < Base
 
   attr_accessor :agent
   
   # creates the Mechanize agent used to do the scraping 
   def create_agent
     self.agent = Mechanize.new
     agent.keep_alive = false
     agent
   end
   
   # Logging in
   def prepare; end # stub
 
   def strip_html( html )
     html.gsub(/<\/?[^>]*>/, '')
   end
   
 end
end