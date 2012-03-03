require 'nokogiri'
require 'rest-client'
require 'sub_search/sub_download'
require 'sub_search/episode'
require 'pathname'

class SubSearch
  def initialize base_dir
    @base_dir = Pathname(base_dir)
    @subtitle_path = @base_dir

    @base_url = 'http://www.podnapisi.net'
    @url = @base_url + '/nl/ppodnapisi/search?sT=1&sJ=2&'
  end

  def find search_string, options={}
    @search_string = search_string
    @options = options
    get!
    parse!
  end

  def url
    string = @url + '&sK=' + CGI.escape(@search_string)
    string += '&sTS=' + @options[:season].to_s  if @options.key?(:season)
    string += '&sTE=' + @options[:episode].to_s if @options.key?(:episode)
    string
  end

  def get!
    #puts "DEBUG: Downloading '#{url}'"
    @raw_data = RestClient.get(url, :timeout => 10)
    #@raw_data = Iconv.conv("utf-8","ISO-8859-1", @raw_data)
    @raw_data.encode!("utf-8","ISO-8859-1")
  end

  def parse!
    @items = []

    doc = Nokogiri::HTML(@raw_data)

    unless doc.content.match /Geen ondertitels gevonden./
      # get tr elements from specific table
      rows = doc.css('table.first_column_title tr').to_a

      # reject th elements
      rows.reject! { |row| row.css('th').count > 0 }

      # reject slecht horenden rows
      rows.reject! { |tr| tr.css('div.subtitles_flags div.n').count > 0 }


      rows.each do |row|
        item = {}
        columns = row.css('td').to_a
        item[:link] = @base_url + columns[0].css('div')[1].css('a').first.attribute('href').value
        @items << item
      end
    end

    @items
  end

  def download!
    @items.each do |item|
      sub_download = SubDownload.new @base_url, item[:link]
      item = sub_download.download

      filename = @subtitle_path.join(item[:name])
      puts "Writing #{filename}"

      File.open(filename, 'w') do |fh|
        fh.write(item[:data])
      end
    end
  end

  def count
    @items.count
  end
end
