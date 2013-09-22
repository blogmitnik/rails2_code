module PreferencesHelper
  def global_prefs
    return Preference.find(:first) if test?
    @global_prefs ||= Preference.find(:first)
  end
end
