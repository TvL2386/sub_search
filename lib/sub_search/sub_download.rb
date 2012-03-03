require 'nokogiri'
require 'rest-client'
require 'libarchive'

class SubDownload
  def initialize base_url, url
    @base_url = base_url
    @url = url
    get!
    parse!
  end

  def get!
    #puts "DEBUG: Downloading '#{@url}'"
    @raw_data = RestClient.get(@url, :timeout => 10)
    @raw_data.encode!("utf-8","ISO-8859-1")
  end

  def parse!
    doc = Nokogiri::HTML @raw_data
    @download_link = @base_url + doc.css('a.button.big.download').first.attribute('href').to_s
  end

  def download
    data = RestClient.get(@download_link, :timeout => 10)

    Archive.read_open_memory(data) do |ar|
      while entry = ar.next_header
        name = entry.pathname
        data = ar.read_data

        return { name: name, data: data, size: data.size }
      end
    end
  end


end