class String
  # Capitalize each word (space separated).
  def capitalize_each
    contact = " "
    split(contact).each{ |word| word.capitalize! }.join(contact)
  end
  
  # Capitalize each word in place.
  def capitalize_each!
    replace capitalize_each
  end
  
  def to_safe_uri
    self.strip.downcase.gsub('&', 'and').gsub(' ', '-').gsub(/[^\w-]/,'')
  end
  
  def from_safe_uri
    self.gsub('-', ' ')
  end

  def add_param args = {}
    self.strip + (self.include?('?') ? '&' : '?') + args.map { |k,v| "#{k}=#{URI.escape(v.to_s)}" }.join('&')
  end
  
  def truncate len = 30
    return self if size <= len
    s = self[0, len - 3].strip
    s << '...'
  end

  def to_formatted_date(format=nil)
    begin
      converted_date_value = Date.strptime(self.gsub(/\D/, '-').gsub(/-\d\d(\d\d)$/,'-\1'), format.gsub(/[\.\/]/, '-'))
      
			if converted_date_value.year < 1000
				converted_date_value = Date.strptime(self.gsub(/\D/, '-'), format.gsub(/[\.\/]/, '-').gsub('%Y', '%y'))
      end      
    rescue
      converted_date_value = Chronic.parse(self)
      converted_date_value = converted_date_value.to_date unless converted_date_value.blank?
    end
    return converted_date_value
  end
  
  
  def valid_email?
    !(self =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i).nil?
  end
end