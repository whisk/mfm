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
      parts = convert_to_mp3(parts)
      joined = join_parts(parts, "#{MFM.settings[:tmp_dir]}/#{filename}.joined")
      trimmed = trim(joined, filename)
    end

    private

    def track_parts
      i = 0
      files = []
      while (i < (duration.to_f / MFM.settings[:part_raw_duration]).ceil + 1) do
        files << format_track_part_url(@data['station']['file'], i)
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
        'NN'   => sprintf('%02d', time.strftime('%M').to_i + num),
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
        part = open("#{MFM.settings[:tmp_dir]}/#{File.basename(url)}.part#{i}", 'wb')
        part.write(open(url).read)
        parts << part.path
        i += 1
      end

      parts
    end

    def convert_to_mp3(parts)
      converted_parts = []

      parts.each do |part_path|
        converted_part_path = "#{part_path}.mp3"
        `#{MFM.settings[:ffmpeg_bin]} -y -i '#{part_path}' -ss #{MFM.settings[:part_offset]} -t #{MFM.settings[:part_duration]} -ab #{MFM.settings[:bitrate]} -f mp3 -vn '#{converted_part_path}'`
        converted_parts << converted_part_path
        File.unlink(part_path)
      end

      converted_parts
    end

    def join_parts(parts, joined_path)
      joined = File.open(joined_path, 'wb')
      parts.each do |part_path|
        File.open(part_path, 'rb') do |part|
          while buff = part.read(4096)
            joined.write(buff)
          end
        end
        File.unlink(part_path)
      end
      joined.close

      return joined.path
    end

    def trim(joined, trimmed)
      `#{MFM.settings[:ffmpeg_bin]} -y -i '#{joined}' -ss #{time.strftime('%S')} -t #{duration} -f mp3 -acodec copy -vn '#{trimmed}'`

      trimmed
    end
  end

end
