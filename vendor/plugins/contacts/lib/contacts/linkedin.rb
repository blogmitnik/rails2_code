class Contacts
  class Linkedin < Base
    URL = "http://linkedin.com"
    LOGIN_URL = "https://www.linkedin.com/secure/login?trk=hb_signin"
    LOGIN_POST_URL = "https://www.linkedin.com/secure/login"
    HOME_URL = "http://www.linkedin.com/home"
    CONTACT_URL = "http://www.linkedin.com/dwr/exec/ConnectionsBrowserService.getMyConnections.dwr"
    REFERER_URL = "http://www.linkedin.com/connections?trk=hb_side_cnts"
    PROTOCOL_ERROR = "LinkedIn has changed its protocols, please upgrade this library."
    
    def real_connect
      data, resp, cookies, forward = get(LOGIN_URL)
      
      if resp.code_type != Net::HTTPOK
        raise ConnectionError, PROTOCOL_ERROR
      end
      
      postdata = "csrfToken=guest_token&session_key=#{@login}&session_password=#{@password}&session_login=Sign In&session_login=&session_rikey="
      
      data, resp, cookies, forward = post(LOGIN_POST_URL, postdata, cookies)
      
      if data.index("The email address or password you provided does not match our records.")
        raise AuthenticationError, "Username and password do not match!"
      elsif data.index('Please enter your password') || data.index('Please enter your email address.')
       raise AuthenticationError, "Email or Password can not be blank!"
      elsif cookies == ""
        raise ConnectionError, PROTOCOL_ERROR
      end
      
      data, resp, cookies, forward = get(HOME_URL, cookies, URL)
      
      if resp.code_type != Net::HTTPOK
        raise ConnectionError, PROTOCOL_ERROR
      end
      
      @ajax_session = get_element_string(data,'name="csrfToken" value="','"')
      @logout_url = "https://www.linkedin.com/secure/login?session_full_logout=&trk=hb_signout"
      @cookies = cookies
    end
    
    def contacts      
   raise ConnectionError, PROTOCOL_ERROR unless @ajax_session
   
   postdata = "callCount=1"
   postdata+= "&JSESSIONID=#{@ajax_session}"
   postdata+= "&c0-scriptName=ConnectionsBrowserService"
   postdata+= "&c0-methodName=getMyConnections"
   postdata+= "&c0-param0=string:0"
   postdata+= "&c0-param1=number:-1"
   postdata+= "&c0-param2=string:DONT_CARE"
   postdata+= "&c0-param3=number:500"
   postdata+= "&c0-param4=boolean:false"
   postdata+= "&c0-param5=boolean:true"
   postdata+= "&xml=true"
   
   data, resp, cookies, forward = ajaxpost(CONTACT_URL, postdata, @cookies, REFERER_URL)
   raise ConnectionError, PROTOCOL_ERROR if resp.code_type != Net::HTTPOK
   cr = /detailsLink=s\d+;(.*?)\.firstName=/
   fr = /emailAddress=s\d+;var s\d+=\"(.*?)\";s\d+/
   er =  /var s\d+=\"(.*?)\";s\d+.emailAddress/
   
   contacts = []
   results = data.scan(cr)
   results.each do |result|
    result = result.to_s
    first_name = result.scan(fr).to_s
    email = result.scan(er).to_s
    contacts << [first_name, email]
   end
   
   logout
   return contacts
    end
    
    def logout
     return false unless @ajax_session
     if @logout_url && @cookies
      url = URI.parse(@logout_url)
       http = open_http(url)
       http.get("#{url.path}?#{url.query}",
        "Cookie" => @cookies
        )
        return true
     end
    end
    
    private
    
    def ajaxpost(url, postdata, cookies="", referer="")
   url = URI.parse(url)
   http = open_http(url)
   resp, data = http.post(url.path, postdata,
     "User-Agent" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1) Gecko/20061010 Firefox/2.0",
     "Accept-Encoding" => "gzip",
     "Cookie" => cookies,
     "Referer" => referer,
     "Content-Type" => 'text/plain;charset=UTF-8'
   )
   data = uncompress(resp, data)
   cookies = parse_cookies(resp.response['set-cookie'], cookies)
   forward = resp.response['Location']
   forward ||= (data =~ /<meta.*?url='([^']+)'/ ? CGI.unescapeHTML($1) : nil)
   if(not forward.nil?) && URI.parse(forward).host.nil?
    forward = url.scheme.to_s + "://" + url.host.to_s + forward
   end
   return data, resp, cookies, forward
    end
    
  end
  TYPES[:linkedin] = Linkedin
end