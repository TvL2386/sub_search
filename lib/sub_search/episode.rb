class Episode
  attr_reader :attributes

  def initialize filename
    @filename = filename
    @attributes = nil
    process
  end

  def process
    if @filename =~ /^(.*)s(\d{2})e(\d{2})[^\d]+/i
      @attributes = { season: $2, episode: $3 }
      @attributes[:name] = $1.gsub(/(1080|720)p?/,'').gsub(/20\d{2}/,'').gsub('.',' ').rstrip
      @attributes[:filename] = @filename
    end
  end
end