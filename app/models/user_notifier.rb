require 'action_controller/integration'

class UserNotifier < ActionMailer::ARMailer
  extend PreferencesHelper
  @@session = ActionController::Integration::Session.new
  
  def domain
    @domain ||= Notifier.global_prefs.domain
  end
  
  def server
    @server_name ||= Notifier.global_prefs.server_name
  end
  
  def forgot_password(user)
    setup_email(user)
    @subject   += "確定重新設定密碼"
    @body[:url] = @@session.url_for(:controller => 'account', 
                        :action => 'reset_password', 
                        :id => user.pw_reset_code, 
                        :only_path => false, 
                        :host => 'railscode.mine.nu')
  end
  
  def signup_notification(user)
    setup_email(user)
    @subject    += '帳號註冊確認信'
    @body[:url]  = "http://railscode.mine.nu/account/activate/#{user.activation_code}"
  end
  
  def activation(user)
    setup_email(user)
    @subject    += '帳號已成功啟用'
    @body[:url]  = "http://railscode.mine.nu/"
  end
  
  def reactivation(user)
    setup_email(user)
    @subject    += '重新啟動確認'
    @body[:url]  = "http://railscode.mine.nu/account/reactivate/#{user.reactivation_code}"
  end
  
  def disable(user)
    setup_email(user)
    @subject    += '你的帳號已經停用'
  end
  
  def invite(inviter, email, name, subject, message)
    @charset        = "utf8"
    @recipients     = email
    @from           = "#{inviter.name} <cateplaces@gmail.com>"
    @sent_on        = Time.now
    @subject        = subject
    @headers        = {}

    # Email body substitutions
    @body[:domain] = server
    @body[:name] = name
    @body[:message] = message
    @body[:inviter] = inviter
    @body[:inviter_profile_url] = profile_path(inviter)
    @body[:url] = "http://railscode.mine.nu/signup"
  end
  
  def group_invite(inviter, group, email, name, subject, message)
    @charset        = "utf8"
    @recipients     = email
    @from           = "#{inviter.name} <cateplaces@gmail.com>"
    @sent_on        = Time.now
    @subject        = subject
    @headers        = {}

    # Email body substitutions
    @body[:domain] = server
    @body[:name] = name
    @body[:message] = message
    @body[:inviter] = inviter
    @body[:group] = group
    @body[:inviter_profile_url] = profile_path(inviter)
    @body[:group_url] = group_path(group)
    @body[:url] = "http://railscode.mine.nu/signup"
  end
  
  protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    @from        = "Cateplaces <cateplaces@gmail.com>"
    @subject     = "Cateplaces "
    @sent_on     = Time.now
    @body[:user] = user
    @charset     = "utf8"
  end
end
