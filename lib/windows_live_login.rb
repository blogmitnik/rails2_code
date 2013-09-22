require 'uri'
require 'base64'
require 'openssl'
require 'net/https'
require 'rexml/document'

class WindowsLiveLogin

  @@login_prefix = "http://login.live.com/wlogin.srf?"
  @@logout_prefix = "http://login.live.com/logout.srf?"

  @@appid = "000000004C0321C2"  # Put your AppID here
  @@secret = "71hkmidJCSDmXfoA3qdhXRfMGAbisgvA" # Put your Secret here

  def initialize(appid=@@appid, secret=@@secret)
    @appid = appid
    @secret = secret
    @cookie = nil
    @stoken = nil
    @token = nil

    @signkey = self.derive("SIGNATURE")
    @cryptkey = self.derive("ENCRYPTION")

    @uid = nil
    @ts = nil
  end

  def uid
    @uid
  end

  def verify_sig(param)
    body, sig = param.split("&sig=")
    sig = Base64.decode64 CGI.unescape(sig)
    return (sig == self.sign_token(body))
  end

  def decrypt()
    token = @token
    iv = token[0..15]
    crypted = token[16..-1]

    begin
      aes128cbc = OpenSSL::Cipher::AES128.new("CBC")
      aes128cbc.decrypt
      aes128cbc.iv = iv
      aes128cbc.key = @cryptkey
      @token = aes128cbc.update(crypted) + aes128cbc.final
    rescue
      return false
    end
  end

  def set_token(stoken)
    return false if !stoken
    @stoken = stoken
    @token = self.u64(stoken)
  end

  def process_token(stoken)
    return nil if !self.set_token(stoken)
    return nil if !self.decrypt()
    return nil if !self.verify_sig(@token)

    @token.split("&").each do |p|
      key, content = p.split("=")
      if key == 'uid'
        @uid = content
        return @uid
        break
      end
    end
  end

  def derive(prefix)
    key = OpenSSL::Digest::SHA256.digest(prefix + @@secret)
    return key[0..15]
  end

  def u64(string)
    return Base64.decode64 CGI.unescape(string) || false
  end

  def sign_token(body, signkey=@signkey)
    digest = OpenSSL::Digest::SHA256.new
    return OpenSSL::HMAC.digest(digest, signkey, body)
  end

  def clear_cookie_response()
    type = "image/gif"
    content = "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAEALAAAAAABAAEAAAIBTAA7"
    content = Base64.decode64(content)
    return type, content
  end


  def self.login_url
    return @@login_prefix + "appid=" + @@appid + "&alg=wsignin1.0"
  end

  def self.logout_url
    return @@logout_prefix + "appid=" + @@appid
  end
end
