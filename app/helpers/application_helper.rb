# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  require 'string'
  require 'object'
  require 'digest/sha1'
  require 'net/http'
  require 'uri'
  require 'smtp-tls'

  def app_name
    name = global_prefs.app_name
    default = "Cateplaces"
    name.blank? ? default : name
  end
  
  def title
    base_title = "#{app_name}"
    if @title.nil?
      base_title
    else
      "#{base_title} | #{@title}"
    end
  end
  
  def liveauth_appid
    live_appid = '000000004C0321C2'
    return live_appid
  end
  
  def get_locale
    locale.to_s
  end
  
  def admin_view?
    params[:controller] =~ /admin/ and admin?
  end
  
  def yes_no(bool)
    if bool == true
      "已發送"
    else
      "尚未發送"
    end
  end
  
  def tag_cloud(tags, classes)
    max, min = 0, 0
    tags.each do |tag|
      max = tag.count if tag.count > max
      min = tag.count if tag.count < min
    end
  
    divisor = ((max - min) / classes.size) + 1
    tags.each do |tag|
      yield tag.name, classes[(tag.count - min) / divisor]
    end
  end
  
  def default_image(object, size)
    return object.class.to_s.downcase + 's_default_' + size.to_s + '.gif' 
  end
  
  def icon_url(object, options)
    field = options.delete(:file_column_field) || 'icon'
    return default_image(object, options[:size]) if field.nil? || object.send(field).nil?
    options = options[:file_column_version] || options
    url_for_image_column(object, 'icon', options)
  end
  
  def icon object, size = :small, img_opts = {}
    return "" if object.nil?
    options = {:size => size, :file_column_version => size }

    if object.is_a?(User)
      img_opts = {:title => object.full_name, :alt => object.full_name, :class => size}.merge(img_opts)
      link_to(avatar_tag(object, {:size => size, :file_column_version => size }, img_opts), profile_path(object), { :title => object.full_name })
    elsif object.is_a?(Group)                     
      url = icon_url(object, options)
      return '' if url.nil? || url.empty?
      html_options = {:title => object.name, :alt => object.name, :class => size}.merge(img_opts)
      link_to(image_tag(url, html_options), group_path(object), :title => object.name )
    elsif object.is_a?(NewsItem)                     
      url = icon_url(object, options)
      return '' if url.nil? || url.empty?
      html_options = {:title => object.title, :alt => object.title, :class => size}.merge(img_opts)
      if object.newsable_type == "Widget"
        link_to(image_tag(url, html_options), member_story_path(object), { :title => object.title })
      elsif object.newsable_type == "Group"
        link_to(image_tag(url, html_options), group_news_path(object.newsable, object), { :title => object.title })
      end
    elsif object.is_a?(Event)                     
      url = icon_url(object, options)
      return '' if url.nil? || url.empty?
      html_options = {:title => object.title, :alt => object.title, :class => size}.merge(img_opts)
      if object.eventable_type == "Group"
        link_to(image_tag(url, html_options), group_event_path(object.eventable, object), { :title => object.title })
      else
        link_to(image_tag(url, html_options), event_path(object), { :title => object.title })
      end
    end
  end
  
  def icon_tag(object, size, css_class = '')
    css = 'class="' + css_class + '"' if css_class
    '<img src="' + icon_url(object, {:size => size, :file_column_version => size }) + '" ' + css + ' />'
  rescue
    # icon_url can return nil.  If it does return an empty string
    ''
  end
  
  def icon_for(upload, size = :icon)
    return '' if upload.nil?
    if upload.is_pdf?
      link_to image_tag('file_icons/pdf.gif', :height => '25'), upload.public_filename
    elsif upload.is_word?
      link_to image_tag('file_icons/word.png', :height => '25'), upload.public_filename  
    elsif upload.is_image?
      link_to image_tag(upload.public_filename(size)), upload.public_filename
    elsif upload.is_mp3?
      link_to image_tag('file_icons/mp3.png', :height => '30'), upload.public_filename
    elsif upload.is_excel?
      link_to image_tag('file_icons/excel.png', :height => '25'), upload.public_filename
    elsif upload.is_text?
      link_to image_tag('file_icons/text.png', :height => '25'), upload.public_filename
    else
      link_to image_tag('blurp_file.png', :height => '25'), upload.public_filename
    end
  rescue => ex
    link_to image_tag('blurp_file.png', :height => '25'), upload.public_filename
  end

  def link_for_shared_uploadable(shared_uploadable)
    case shared_uploadable.class.name
    when 'User'
      link_to(h(shared_uploadable.full_name), profile_path(shared_uploadable))
    when 'Group'
      link_to(h(shared_uploadable.name), group_path(shared_uploadable))
    end
  end
  
  
  def xfn_rel_tag(user, friendship)
    rel_tag = []
    if user.id == friendship.friend.id
      # identity
      rel_tag << 'me'
    else
      # friendship
      rel_tag << 'friend' if friendship.xfn_friend
      rel_tag << 'acquaintance' if friendship.xfn_acquaintance
      rel_tag << 'contact' if friendship.xfn_contact
      
      #physical
      rel_tag << 'met' if friendship.xfn_met
      
      #professional
      rel_tag << 'coworker' if friendship.xfn_coworker
      rel_tag << 'colleague' if friendship.xfn_colleague
      
      #geographical
      rel_tag << 'coresident' if friendship.xfn_coresident
      rel_tag << 'neighbor' if friendship.xfn_neighbor
      
      #family
      rel_tag << 'child' if friendship.xfn_child
      rel_tag << 'parent' if friendship.xfn_parent
      rel_tag << 'sibling' if friendship.xfn_sibling
      rel_tag << 'spouse' if friendship.xfn_spouse
      rel_tag << 'kin' if friendship.xfn_kin
      
      #romantic
      rel_tag << 'muse' if friendship.xfn_muse
      rel_tag << 'crush' if friendship.xfn_crush
      rel_tag << 'date' if friendship.xfn_date
      rel_tag << 'sweetheart' if friendship.xfn_sweetheart
    end
    rel_tag.join(' ')
  end
  
  # Return true if results should be paginated.
  def paginated?
    @pages and @pages.length > 1
  end
  
  def admin_view?
    params[:controller] =~ /admin/ and admin?
  end
  
  def admin?
    is_logged_in? and logged_in_user.has_role?('Administrator')
  end
  
  def moderator?
    is_logged_in? and logged_in_user.has_role?('Moderator')
  end
  
  def logged_in_user?(user)
    is_logged_in? and user == logged_in_user
  end
  
  def me
    logged_in_user == @user
  end
  
  def is_me?(user)
    user == logged_in_user
  end
  
  def self_wall
    logged_in_user?(@user) && logged_in_user?(@banter)
  end
  
  # Return true if a user is connected to (or is) the logged_in_user
  def connected_to?(user)
    logged_in_user?(user) or Friendship.connected?(user, logged_in_user)
  end
  
  # Return true if a user and commenter are connected to (or is) the logged_in_user
  def double_connected_to?(user, banter)
    user.friends.include?(banter) && user.has_wall_with(banter) && 
      logged_in_user.friends.include?(user) && logged_in_user.friends.include?(banter)
  end

  # Set the input focus for a specific id
  # Usage: <%= set_focus_to 'form_field_label' %>
  def set_focus_to(id)
    javascript_tag(" $(document).ready(function(){$('##{id}').focus()});");
  end
  
  # Display text by sanitizing and formatting.
  # The formatting is done by Markdown via the BlueCloth gem.
  # The html_options, if present, allow the syntax
  #  display("foo", :class => "bar")
  #  => '<p class="bar">foo</p>'
  def display(text, html_options = nil)
    begin
      if html_options
        html_options = html_options.stringify_keys
        tag_opts = tag_options(html_options)
      else
        tag_opts = nil
      end
      processed_text = markdown(sanitize(text))
    rescue
      # Sometimes Markdown throws exceptions, so rescue gracefully.
      processed_text = content_tag(:p, sanitize(truncate(text, 150)))
    end
    add_tag_options(processed_text, tag_opts)
  end
  
  # Output a column div.
  # The current two-column layout has primary & secondary columns.
  # The options hash is handled so that the caller can pass options to 
  # content_tag.
  # The LEFT, RIGHT, and FULL constants are defined in 
  # config/initializers/global_constants.rb
  def column_div(options = {}, &block)
    klass = options.delete(:type) == :primary ? "col1" : "col2"
    # Allow callers to pass in additional classes.
    options[:class] = "#{klass} #{options[:class]}".strip
    content = content_tag(:div, capture(&block), options)
    concat(content, block.binding)
  end

  def email_link(user, options = {})
    reply = options[:replying_to]
    if reply
      path = reply_message_path(reply)
    else
      path = new_user_message_path(user)
    end
    img = image_tag("icons/message.gif")
    action = reply.nil? ? "寫信給 #{user.name}" : "回覆訊息給 #{user.name}"
    opts = { :class => 'email-link' }
    str = link_to(img, path, opts)
    str << "&nbsp;"
    str << link_to_unless_current(action, path, opts)
  end

  def formatting_note
    %(支援 HTML 和
      #{link_to("Markdown",
                "http://daringfireball.net/projects/markdown/basics",
                :popup => true)} 語法)
  end
  
  def custom_form_for(record_or_name_or_array, *args, &proc) 
    options = args.detect { |argument| argument.is_a?(Hash) } 
    if options.nil? 
      options = {:builder => CustomFormBuilder} 
      args << options 
    end 
    options[:builder] = CustomFormBuilder unless options.nil? 
    form_for(record_or_name_or_array, *args, &proc) 
  end

  def custom_remote_form_for(record_or_name_or_array, *args, &proc) 
    options = args.detect { |argument| argument.is_a?(Hash) } 
    if options.nil? 
      options = {:builder => CustomFormBuilder} 
      args << options 
    end 
    options[:builder] = CustomFormBuilder unless options.nil? 
    remote_form_for(record_or_name_or_array, *args, &proc) 
  end
  
  def cate_form_for name, *args, &block
    options = args.last.is_a?(Hash) ? args.pop : {}
    options = options.merge(:builder=>CateFormBuilder)
    args = (args << options)
    form_for name, *args, &block
  end
  
  def cate_remote_form_for name, *args, &block
    options = args.last.is_a?(Hash) ? args.pop : {}
    options = options.merge(:builder=>CateFormBuilder)
    args = (args << options)
    remote_form_for name, *args, &block
  end
  
  def inline_tb_link link_text, inlineId, html = {}, tb = {}
    html_opts = {
      :title => '',
      :class => 'thickbox'
    }.merge!(html)
    tb_opts = {
      :height => 300,
      :width => 400,
      :inlineId => inlineId
    }.merge!(tb)
    
    path = '#TB_inline'.add_param(tb_opts)
    link_to(link_text, path, html_opts)
  end
  
  def tb_video_link youtube_unique_path
    return if youtube_unique_path.blank?
    youtube_unique_id = youtube_unique_path.split(/\/|\?v\=/).last.split(/\&/).first
    p youtube_unique_id
    client = YouTubeG::Client.new
    video = client.video_by YOUTUBE_BASE_URL+youtube_unique_id rescue return "(video not found)"
    id = Digest::SHA1.hexdigest("--#{Time.now}--#{video.title}--")
    inline_tb_link(video.title, h(id), {:title => video.title}, {:height => 355, :width => 430}) + %(<div id="#{h id}" style="display:none;">#{video.embed_html}</div>)
  end
  
  def you_tube_video video_unique_path
    return if video_unique_path.blank?
    if video_unique_path.match(/youtube\.com/) != nil
      video_id = video_unique_path.split(/\/|\?v\=/).last.split(/\&/).first
      client = YouTubeG::Client.new
      video = client.video_by GlobalConfig.youtube_base_url+video_id rescue return "(video not found)"
      id = Digest::SHA1.hexdigest("--#{Time.now}--#{video.title}--")
      %(<div id="#{h(id)}">#{video.embed_html}</div>)
    else
      video_id = video_unique_path.split(/videoplay\?docid=/).last.split(/\&/).first
      %(<div>#{google_video_embed_html(video_id)}</div>)
    end
  end

  def google_video_embed_html(video_id)
    '<embed id="VideoPlayback" src="http://video.google.com/googleplayer.swf?docid=' + video_id + '&hl=en&fs=true" style="width:400px;height:326px" allowFullScreen="true" allowScriptAccess="always" type="application/x-shockwave-flash"> </embed>'
  end
  
  def body_content blog
    youtube_videos = blog.body.scan(/\[youtube:+.+\]|\[googlevideo:+.+\]/)
    body = blog.body.dup.gsub(/\[youtube:+.+\]|\[googlevideo:+.+\]/, '')
    out = sanitize(body)
    #out = sanitize(textilize(body)) TODO textilize messes up the html from the WYSIWYG.  Figure out how to specify whether or not to use it.
    unless youtube_videos.empty?
      out << <<-EOB
      <strong>內容包含 #{youtube_videos.size} 則影片連結</strong><br/>
      EOB
      youtube_videos.each do |o|
        out << you_tube_video(o.gsub!(/\[youtube\:|\]|\[googlevideo\:/, ''))
      end
    end
    out
  end
  
  # only use this on content that has already been sanitized or whitelisted.
  def process_body_content(item)
    youtube_videos = item.body.scan(/\[youtube:+.+\]|\[googlevideo:+.+\]/)
    out = item.body.dup.gsub(/\[youtube:+.+\]|\[googlevideo:+.+\]/, '')
    unless youtube_videos.empty?
      out << <<-EOB
      <strong>內容包含 #{youtube_videos.size} 則影片連結</strong><br/>
      EOB
      youtube_videos.each do |o|
        out << you_tube_video(o.gsub!(/\[youtube\:|\]|\[googlevideo\:/, ''))
      end
    end
    '<p>' + out + '</p>'
  end

  def summarize(content, length = 100)
    return '' if content.nil?
    truncate(sanitize(strip_tags(content.dup.gsub(/\[youtube:+.+\]/, ''))), length)
  end

  def html_summarize(content, length = 100)
    truncate(sanitize(content.dup.gsub(/\[youtube:+.+\]/, '')), length)
  end
  
  def is_controller?(controller, &block)
    if params[:controller] == controller
      content = capture(&block)
      concat(content, block.binding)
    end
  end


  private
  
    def inflect(word, number)
      number > 1 ? word.pluralize : word
    end
  
    def add_tag_options(text, options)
      text.gsub("<p>", "<p#{options}>")
    end
  
    # Format text using BlueCloth (or RDiscount) if available.
    def format(text)
      if text.nil?
        ""
      elsif defined?(RDiscount)
        RDiscount.new(text).to_html
      elsif defined?(BlueCloth)
        BlueCloth.new(text).to_html
      elsif no_paragraph_tag?(text)
        content_tag :p, text
      else
        text
      end
    end
    
    # Is a Markdown library present?
    def markdown?
      defined?(RDiscount) or defined?(BlueCloth)
    end
    
    # Return true if the text *doesn't* start with a paragraph tag.
    def no_paragraph_tag?(text)
      text !~ /^\<p/
    end
end
