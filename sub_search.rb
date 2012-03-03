$:.unshift('lib')

require "bundler/setup"

require 'sub_search'
require 'awesome_print'
require 'rb-inotify'

path = '/data/shared/Series'

puts "Changing working directory to #{path}"
Dir.chdir(path) do
  notifier = INotify::Notifier.new

  puts "Waiting for inotify events..."
  notifier.watch('.', :moved_to, :create) do |event|
    filename = event.name

    puts "Event for file: #{filename}"

    if filename !~ /\.(mkv|mp4|avi)$/i
      puts "Ignoring this extension\n"
      next
    end

    episode = Episode.new filename
    puts "Parsed filename to #{episode.attributes.inspect}"
    if episode.attributes
      sub_search = SubSearch.new(Dir.getwd)
      sub_search.find(episode.attributes[:name], season: episode.attributes[:season], episode: episode.attributes[:episode])
      puts "Found #{sub_search.count} subtitles"
      if sub_search.count > 0
        sub_search.download!
      end
    else
      puts "Failed to parse filename"
    end

    puts
  end

  notifier.run
end
