require 'open-uri'

module MFM
  @@settings = {}

  def self.init(settings = {})
    settings.each {|k, v| @@settings[k.to_sym] = v}
  end

  def self.settings
    @@settings
  end

  class Track
    @data = {}
    @duration = 0

    def initialize(data = {})
      @data = data

      if (@data['trackinfo']['duration'] =~ (/(?:(\d+):)?(\d+)/))
        @duration = $1.to_i * 60 + $2.to_i
      end
      puts @data.inspect
    end

    def trackname
      return @data['trackinfo']['trackname']
    end

    def artistname
      return @data['trackinfo']['artistname']
    end

    def time
      Time.at(@data['trackinfo']['timestamp'].to_i)
    end

    def duration
      @duration
    end

    def save_as_mp3(filename)
      parts = download_parts



      puts files.inspect
    end

    private

    def track_parts
      t = 0
      i = 1
      files = []
      while (t <= duration) do
        files << format_track_part_url(@data['station']['file'], i)
        t += MFM.settings[:track_part_duration]
        i += 1
      end

      files
    end

    def format_track_part_url(tpl, num)
      data = {
        'YYYY' => time.strftime('%Y'),
        'MM'   => time.strftime('%m'),
        'DD'   => time.strftime('%d'),
        'HH'   => time.strftime('%H'),
        'NN'   => sprintf('%02d', num),
      }
      data.each do |k, v|
        tpl = tpl.sub(/#{k}/, v)
      end

      return tpl
    end

    def download_parts
      parts = []
      i = 1
      track_parts.each do |url|
        part = open("#{MFM.settings[:tmp_dir]}/#{}.part#{i}", 'wb')
        part.write(open(url).read)
        parts << part.path
        i += 1
      end

      parts
    end
  end

end
