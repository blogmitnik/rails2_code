require 'open-uri'
require 'cgi'
require 'rexml/document'

module Yahoo

class ResultItem
  def initialize(e)
    @url = e.get_text('ClickUrl').value
    @display_url = e.get_text('Url').value
    @title = e.get_text('Title').value
    @height = e.get_text('Height').value.to_i
    @width = e.get_text('Width').value.to_i
    @summary = e.get_text('Summary')
    @summary = @summary.value if @summary
    @restrictions = e.get_text('Restrictions')
    @restrictions = @restrictions.value if @restrictions
    @copyright = e.get_text('Copyright')
    @copyright = @copyright.value if @copyright
    @referer_url = e.get_text('RefererUrl')
    @referer_url = @referer_url.value if @referer_url
  end
  attr_reader :url, :display_url, :title, :summary, :restrictions, :thumbnail, :copyright, 
              :height, :width, :referer_url
end

class ImageSearch
  include REXML
  def initialize(appid, max = 10, adult = false)
    @appid = appid
    @max = max
    @adult = adult
  end
  def search(q, i = 1)
    r = []
    doc = Document.new(
         open("http://search.yahooapis.com/ImageSearchService/V1/imageSearch?" +
              "appid=#{CGI.escape(@appid)}&query=#{CGI.escape(q)}#{start(i)}#{max}#{adult}"))
    doc.root.each_element('Result') do |e|
      r << ResultItem.new(e)
    end
    r
  end

  private
  def start(i)
    "&start=#{i * @max - (@max - 1)}"
  end

  def max
    "&results=#{@max}"
  end

  def adult
    (@adult) ? '&adult_ok=1' : ''
  end
end

end

if $0 == __FILE__
  if ARGV.length == 0
    puts 'usage: ruby yahoo_search.rb query-word'
    exit(1)
  end
  e = Yahoo::ImageSearch.new('rJUi5qnIkY.YomYEHcluO5GzYxblrxdw8VWv4oWoC6U-').search(ARGV[0])
  e.each do |x|
    puts "#{x.title}, #{x.thumbnail}, #{x.copyright}"
    puts "w=#{x.width}, h=#{x.height}, sum="#{x.summary}"
    puts "url=#{x.url}, restrictions=#{x.restrictions}"
  end
end
