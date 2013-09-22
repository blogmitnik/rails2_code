# == Schema Information
# Schema version: 32
#
# Table name: contacts
#
#  id            :integer(11)     not null, primary key
#  user_id       :integer(11)     not null
#  msn_account   :string(255)
#  ichat_account :string(255)
#  gtalk_account :string(255)
#  aim_account   :string(255)
#  phone         :string(255)
#  cell_phone    :string(255)
#  address       :string(255)
#  city          :string(255)
#  zipcode       :integer(11)
#  website       :text
#

class Contact < ActiveRecord::Base
  belongs_to :user

  is_indexed :fields => [ 'city', 'state', 'zipcode', 'gender', 'hometown', 'birthday', 'school', 'school_year', 'high_school', 'high_school_year', 'employer' ]
  
  SCHOOL_YEAR_SELECT = [
  "2014", "2013", "2012", "2011", "2010", "2009", "2008", "2007", "2006", "2005", 
  "2004", "2003", "2002", "2001", "2000", "1999", "1998", "1997", "1996", "1995", 
  "1994", "1993", "1992", "1991", "1990", "1989", "1988", "1987", "1986", "1985", 
  "1984", "1983", "1982", "1981", "1980", "1979", "1978", "1977", "1976", "1975", 
  "1974", "1973", "1972", "1971", "1970", "1969", "1968", "1967", "1966", "1965", 
  "1964", "1963", "1962", "1961", "1960", "1959", "1958", "1957", "1956", "1955", 
  "1954", "1953", "1952", "1951", "1950", "1949", "1948", "1947", "1946", "1945", 
  "1944", "1943", "1942", "1941", "1940", "1939", "1938", "1937", "1936", "1935", 
  "1934", "1933", "1932", "1931", "1930", "1929", "1928", "1927", "1926", "1925", 
  "1924", "1923", "1922", "1921", "1920", "1919", "1918", "1917", "1916", "1915", 
  "1914", "1913", "1912", "1911", "1910"]
                                
  CITIES_SELECT = 
    ["United States of America", "Canada", "Afghanistan", "Albania", "Algeria", "American Samoa", "Andorra", 
    "Antarctica", "Antigua and Barbuda", "Argentina", "Armenia", "Aruba", "Australia", "Austria", "Azerbaijan", 
    "Bahamas", "Bahrain", "Bangladesh", "Barbados", "Belarus", "Belgium", "Belize", "Benin", "Bermuda", "Bhutan", 
    "Bolivia", "Bosnia and Herzegovina", "Botswana", "Bouvet Island", "Brazil", "British Indian Ocean Territory", 
    "Brunei Darussalam", "Bulgaria", "Bulgaria", "Burkina Faso", "Burundi", "Burundi", "Cambodia", "Cameroon", 
    "Cape Verde", "Cayman Islands", "Central African Republic", "Chad", "Chile", "China", "Christmas Island", 
    "Cocos (Keeling) Islands", "Cocos", "Colombia", "Comoros", "Congo", "Cook Islands""Costa Rica", "Cote d'Ivoire", 
    "Croatia", "Cuba", "Cuba", "Cyprus", "Czech Republic", "Denmark", "Djibouti", "Dominica", "Dominican Republic",
    "Ecuador", "El Salvador", "Equatorial Guinea", "Eritrea", "Estonia", "Ethiopia", "Falkland Islands", 
    "Faroe Islands", "Fiji", "Finland", "France", "French Guiana", "French Polynesia", "French Southern Territories", 
    "Gabon", "Gambia", "Georgia", "Germany", "Ghana", "Gibraltar", "Greec", "Greenland", "Grenada", "Guadeloupe", 
    "Guam", "Guatemala", "Guernsey", "Guinea", "Guinea-Bissau", "Guyana", "Haiti", "Heard Island and McDonald Islands", 
    "Holy See (VaticanCityState)", "Honduras", "Hong Kong", "Hungary", "Iceland", "India", "Indonesia", "Iran", 
    "Iraq", "Ireland", "Isle of Man", "Israel", "Italy", "Jamaica", "Japan", "Jersey", "Jordan", "Kazakhstan", 
    "Kenya", "Kiribati", "Korea", "Kuwait", "Kyrgyzstan", "Kyrgyzstan", "Laos", "Latvia", "Lebanon", "Lesotho", 
    "Liberia", "Libyan Arab Jamahiriya", "Liechtenstein", "Lithuania", "Luxembourg", "Macao", "Macedonia", 
    "Madagascar", "Malawi", "Malaysia", "Maldives", "Mali", "Malta", "Marshall Islands", "Martinique", 
    "Mauritania", "Mauritius", "Mayotte", "Mexico", "Micronesia", "Moldova", "Monaco", "Mongolia", "Montenegro", 
    "Montserrat", "Morocco", "Mozambique", "Myanmar", "Namibia", "Nauru", "Nepal", "Netherlands", "Netherlands Antilles", 
    "New Caledonia", "New Zealand", "Nicaragua", "Niger", "Nigeria", "Niue", "Norfolk Island", "Northern Mariana Islands", 
    "Norway", "Oman", "Pakistan", "Palau", "Palestinian Territory", "Panama", "Papua New Guinea", "Paraguay", "Peru", 
    "Philippines", "Pitcairn", "Poland", "Portugal", "Puerto Rico", "Qatar", "Reunion", "Romania", "Russian Federation", 
    "Rwanda", "Saint Helena", "Saint Kitts and Nevis", "Saint Lucia", "Saint Pierre and Miquelon", "Saint Vincent and the Grenadines", 
    "Samoa", "San Marino", "Sao Tome and Principe", "Saudi Arabia", "Senegal", "Senegal", "Serbia", "Seychelles", 
    "Sierra Leone", "Singapore", "Slovakia", "Slovenia", "Solomon Islands", "Somalia", "South Africa", 
    "South Georgia and the South Sandwich Islands", "Spain", "SriLanka", "Sudan", "Suriname", "Svalbard and Jan Mayen", 
    "Swaziland", "Sweden", "Switzerland", "Syrian Arab Republic", "Taiwan", "Tajikistan", "Tanzania", "Thailand", 
    "Timor-Leste", "Togo", "Tokelau", "Tonga", "Trinidad and Tobago", "Tunisia", "Turkey", "Turkmenistan", "Turks and Caicos Islands", 
    "Tuvalu", "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom", "United States Minor Outlying Islands", "Uruguay", 
    "Uzbekistan", "Vanuatu", "Venezuela", "VietNam", "Virgin Islands-British", "Virgin Islands-U.S.", "Wallis and Futuna", 
    "Western Sahara", "Yemen", "Zambia", "Zimbabwe"]
    
  AGE_SELECT = [
  "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", 
  "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", 
  "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", "61", "62", 
  "63", "64", "65", "66", "67", "68", "69", "70", "71", "72", "73", "74", "75", "76", "77", 
  "78", "79", "80", "81", "82", "83", "84", "85", "86", "87", "88", "89", "90", "91", "92", 
  "93", "94", "95", "96", "97", "98", "99", "100", "101", "102", "103", "104", "105", "106", 
  "107", "108"]
    
  DEPT_SELECT = ["就讀大專院校", "就讀研究所"]
  
  GENDER_SELECT = ["男性", "女性"]
  
  AFFECTION_SELECT = ["單身", "交往中", "已訂婚", "已婚", "一言難盡", "開放性交往中"]
  
  SHOW_BIRTHDAY_SELECT = [
    ["在個人檔案中顯示我的生日", true], ["不要在個人檔案中顯示我的生日", false]
  ]
  
  ZIP_CODE_MIN_LENGTH = 3
  ZIP_CODE_MAX_LENGTH = 5
  ZIP_CODE_RANGE = ZIP_CODE_MIN_LENGTH..ZIP_CODE_MAX_LENGTH
  
  COMMON_MAX_LENGTH = 30
  COMMON_FIELD_SIZE = 30
  PHONE_MAX_LENGTH = 20
  STATE_MAX_LENGTH = 20
  SCHOOL_MAX_LENGTH = 50
  
  COMMON_ROWS = 6
  COMMON_COLS = 40
  
  IM_ACCOUNT_MAX_LENGTH = 100
  ADDRESS_MAX_LENGTH = 200
  WEBSITE_MAX_LENGTH = 3000
  
  ZIPCODE_SIZE = 10
  STATE_SIZE = 20
  SCHOOL_SIZE = 30
  COMMON_SIZE = 20
  
  validates_inclusion_of :city, :in => CITIES_SELECT, :message => "您選擇城市不在列表之中", :on => :update, :allow_blank => true
  validates_length_of :state, :maximum => STATE_MAX_LENGTH, :on => :update, 
                      :message => "你輸入的地名太長了", :allow_blank => true
  validates_length_of :zipcode, :within => ZIP_CODE_RANGE, :on => :update, 
                      :message => "您只能輸入3到5碼的郵遞區號", :allow_blank => true
  validates_length_of :cell_phone, :maximum => PHONE_MAX_LENGTH, :on => :update, :allow_blank => true
  validates_length_of :phone, :maximum => PHONE_MAX_LENGTH, :on => :update, :allow_blank => true
  validates_length_of :msn_account, :ichat_account, :gtalk_account, :aim_account, :maximum => IM_ACCOUNT_MAX_LENGTH, 
                      :on => :update, :message => "您輸入的帳號名稱太長了", :allow_blank => true
  validates_length_of :address, :maximum => ADDRESS_MAX_LENGTH, :on => :update, :allow_blank => true
  validates_length_of :website, :maximum => WEBSITE_MAX_LENGTH, :on => :update, :allow_blank => true
  
  validates_numericality_of :zipcode, :message => "郵遞區號只能包含阿拉伯數字", :on => :update, :allow_blank => true
  validates_numericality_of :cell_phone, :message => "手機號碼只能包含阿拉伯數字", :on => :update, :allow_blank => true
  validates_numericality_of :phone, :message => "電話號碼只能包含阿拉伯數字", :on => :update, :allow_blank => true
  
  validates_length_of :school, :maximum => SCHOOL_MAX_LENGTH, :on => :update, :allow_blank => true
  validates_length_of :high_school, :maximum => SCHOOL_MAX_LENGTH, :on => :update, :allow_blank => true
  validates_length_of :major, :maximum => COMMON_MAX_LENGTH, :on => :update, :allow_blank => true
  validates_length_of :employer, :maximum => COMMON_MAX_LENGTH, :on => :update, :allow_blank => true
  validates_length_of :position, :maximum => COMMON_MAX_LENGTH, :on => :update, :allow_blank => true
  validates_length_of :country, :maximum => COMMON_MAX_LENGTH, :on => :update, :allow_blank => true
  validates_length_of :brief, :maximum => 2000, :on => :update, :allow_blank => true
  
  validates_inclusion_of :dept, :in => DEPT_SELECT, :message => "請選擇正確的學院部", :on => :update, :allow_blank => true
  validates_inclusion_of :school_year, :in => SCHOOL_YEAR_SELECT, :message => "請選擇正確的學年", :on => :update, :allow_blank => true
  validates_inclusion_of :high_school_year, :in => SCHOOL_YEAR_SELECT, :message => "請選擇正確的學年", :on => :update, :allow_blank => true
  
  validates_date :birthday, :before => 13.years.ago.to_date, :after => 82.years.ago.to_date, 
                 :message => "請使用正確的日期格式", :on => :update
  
  validates_inclusion_of :gender, :in => GENDER_SELECT, :message => "請選擇正確的性別", :on => :update, :allow_blank => true
  validates_inclusion_of :affection, :in => AFFECTION_SELECT, :message => "請選擇正確的感情狀態", :on => :update, :allow_blank => true
  
  def post
    ["在", employer, "擔任", position].join(" ")
  end
  
  def age
    return if birthday.nil?
    today = Date.today
    if (today.month > birthday.month) or (today.month == birthday.month and today.day >= birthday.day)
      today.year - birthday.year
    else
      today.year - birthday.year - 1
    end
  end
  
  def website= val
    write_attribute(:website, fix_http(val))
  end
  
  def location
    if not zipcode.blank? and (city.blank? or state.blank?)
      lookup = GeoDatum.find_by_zipcode(zipcode)
      if lookup
        self.city  = lookup.city.capitalize_each if city.blank?
        self.state = lookup.state if state.blank?
      end
    end
    [city, state, zipcode].join(" ")
  end
  
  protected
  
  def fix_http str
    return '' if str.blank?
    str.starts_with?('http') ? str : "http://#{str}"
  end
  
  def after_update
    self.user.update_attribute(:last_activity, "修改了個人檔案資料")
    self.user.update_attribute(:last_activity_at, Time.now)
  end
  
  # Find by age, sex, location.
  def self.find_by_asl(params)
    where = []
    # Set up the age restrictions as birthdate range limits in SQL.
    unless params[:min_age].blank?
      where << "ADDDATE(birthday, INTERVAL :min_age YEAR) < CURDATE()"
    end
    unless params[:max_age].blank?
      where << "ADDDATE(birthday, INTERVAL :max_age+1 YEAR) > CURDATE()"
    end  
    # Set up the gender restriction in SQL.
    where << "gender = :gender" unless params[:gender].blank?
    # Set up the polity restriction in SQL.
    where << "polity = :polity" unless params[:polity].blank?
    # Set up the religion restriction in SQL.
    where << "religion = :religion" unless params[:religion].blank?
    # Set up the school restriction in SQL.
    where << "school = :school" unless params[:school].blank?
    # Set up the school year restriction in SQL.
    where << "school_year = :school_year" unless params[:school_year].blank?
    
    # Set up the distance restriction in SQL.
    zip_code = params[:zipcode]
    unless zip_code.blank? and params[:miles].blank?
      location = GeoDatum.find_by_zipcode(zip_code)
      distance = sql_distance_away(location)
      where << "#{distance} <= :miles"
    end
    
    if where.empty?
      []
    else
      find(:all,
           :joins => "LEFT JOIN geo_data ON geo_data.zipcode = contacts.zipcode",
           :conditions => [where.join(" AND "), params],
           :order => "zipcode")
    end 
  end
  
  private

  # Return SQL for the distance between a spec's location and the given point.
  # See http://en.wikipedia.org/wiki/Haversine_formula for more on the formula.
  def self.sql_distance_away(point)
    h = "POWER(SIN((RADIANS(latitude - #{point.latitude}))/2.0),2) + " +
        "COS(RADIANS(#{point.latitude})) * COS(RADIANS(latitude)) * " + 
        "POWER(SIN((RADIANS(longitude - #{point.longitude}))/2.0),2)" 
    r = 3956 # Earth's radius in miles
    "2 * #{r} * ASIN(SQRT(#{h}))"
  end
end
