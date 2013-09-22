# Use ActiveSupport's version of JSON if available
if !Object.const_defined?('ActiveSupport')
  require 'json/add/rails'
end

class Contacts
  
 def self.parse_json(string)
   if Object.const_defined?('ActiveSupport') && ActiveSupport.const_defined?('JSON')
     ActiveSupport::JSON.decode(string)
   elsif Object.const_defined?('JSON')
     JSON.parse(string)
   else
     raise 'Contacts requires JSON or Rails (with ActiveSupport::JSON)'
   end
 end
  
 class Twitter < Base
  
  URL = "http://twitter.com"
  LOGIN_URL = "http://twitter.com/account/verify_credentials."
  CONTACT_URL = "http://twitter.com/statuses/friends."
  DMESSAGE_URL = "http://twitter.com/direct_messages/new."
  LOGOUT_URL = "http://twitter.com/account/end_session."
  PROTOCOL_ERROR = "Twitter has changed its protocols, please upgrade this library."
    
  def real_connect
   format = 'xml'
   api_url = LOGIN_URL + format
   url = URI.parse(api_url)
   req = Net::HTTP::Get.new(url.path)
   req.basic_auth(@login, @password)
   resp = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
     
   if resp.code_type == Net::HTTPUnauthorized
    raise AuthenticationError, "Username and password do not match!"
   elsif resp.code_type != Net::HTTPOK
    raise ConnectionError, PROTOCOL_ERROR
   end
     
   return true
  end
   
  def contacts
   format = 'json'
   api_url = CONTACT_URL + format
   url = URI.parse(api_url)
   req = Net::HTTP::Get.new(url.path)
   req.basic_auth(@login, @password)
   resp = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
     
   if resp.code_type != Net::HTTPOK
    raise ConnectionError, PROTOCOL_ERROR
   end
      
   data = resp.body
   data = Contacts.parse_json(data) if data
   return [] if data.empty?
   contacts = []
   data.each do |d|
    contacts << [d['name'],d['id']]
   end
   return contacts
      
  end
   
  def send_message(contact, msg, format = 'json')
   return "Direct Message must been less than 140 characters." if msg && msg.length > 160
   return "Direct Message must have something in it..." if msg.nil? || msg.length < 1
     
   api_url = DMESSAGE_URL + format
   url = URI.parse(api_url)
   req = Net::HTTP::Post.new(url.path)
   req.basic_auth(@login, @password)
   req.set_form_data({'user' => contact.last, 'text'=> msg }, '&')
   resp = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
   return true if resp.code_type == Net::HTTPOK
   return false
  end
   
  def logout
   #...
  end
   
 end
 TYPES[:twitter] = Twitter
end