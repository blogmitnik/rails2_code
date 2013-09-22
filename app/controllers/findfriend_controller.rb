class FindfriendController < ApplicationController
  before_filter :login_required
  
  def index  
    @title = "尋找朋友"
    @letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("")
    if params[:id] 
      @initial = params[:id] 
      @pages, users = paginate(:users, 
                               :conditions => ["last_name LIKE ?", @initial+"%"], 
                               :order => "last_name, first_name", 
                               :per_page => 20)
      @users = users.collect { |user| user }
    end  
  end

  def browse
    @title = "尋找朋友"
    return if params[:commit].nil?
    if valid_input?
      contacts = Contact.find_by_asl(params)
      @pages, @users = paginate(contacts.collect { |contact| contact.user })
    end
  end

  def search
    @title = "搜尋"
    if params[:q]
      query = params[:q]
      begin
        # First find the user hits...
        @users = User.find_by_contents(query, :limit => :all)
        # ...then the subhits.
        contacts  =  Contact.find_by_contents(query, :limit => :all)
        # Combine into one list of distinct users sorted by last name.
        hits = contacts
        @users.concat(hits.collect { |hit| hit.user }).uniq!        
        # Sort by last name (requires a spec for each user).
        @users.each { |user| user ||= User.new }      
        @users = @users.sort_by { |user| user.last_name }
        # Adding pagination to search.
        @pages, @users = paginate(@users)
      rescue Ferret::QueryParser::QueryParseException
        @invalid = true
      end
    end
  end
  
  private
  
  # Return true if the browse form input is valid, false otherwise.
  def valid_input?
    @contact = Contact.new
    zip_code = params[:zipcode]
    @contact.zipcode = zip_code
    # The zip code is necessary if miles are provided.
    miles = params[:miles]
    if miles and zip_code.blank?
      @contact.errors.add(:zipcode, "不能保留空白")
    end
    # There are a good number of zip codes for which we have no information.
    location = GeoDatum.find_by_zipcode(zip_code)
    if @contact.valid? and not zip_code.blank? and location.nil?
      @contact.errors.add(:zipcode, "找不到這個郵遞區號")
    end
    # The number of miles should convert to a valid float.
    if !zip_code.blank? and miles.blank?
      @contact.errors.add(:miles, "請輸入要搜尋的範圍")
    elsif !miles.blank? and not miles.valid_float?
      @contact.errors.add(:miles, "請輸入合法的搜尋範圍")
    end
    # The input is valid iff the errors object is empty.
    @contact.errors.empty?
  end

end
