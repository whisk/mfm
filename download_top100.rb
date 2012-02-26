#!/usr/bin/env ruby

require 'xmlsimple'
require 'lib/mfm'
require 'open-uri'

station = ARGV[0]
basedir = ARGV[1] || '.'

station_playlist_url = "http://www.moskva.fm/player_xml.playlist.html?playlist=null&__xmlchart=stations&__xmltype=#{URI.escape(station)}&__xmladd=&rnd=0%2E36734794871881604"

print "Downloading station '#{station}' playlist...\n"
data = XmlSimple.xml_in open(station_playlist_url).readlines.join(''), {'ForceArray' => false}
print "Done\n"

Dir.mkdir(basedir) unless File.directory?(basedir)

MFM.init(YAML.load_file('settings.yml'))
i = 1
data['tracks']['track'].each do |t|
  track = MFM::Track.new(t)
  mp3_file = "#{basedir}/#{track.artistname} - #{track.trackname}.mp3"
  print "Saving track ##{i} into '#{mp3_file}'... "

  unless File.exist?(mp3_file)
    begin
      track.save_as_mp3(mp3_file)
    rescue Interrupt => e
      puts "Interrupting..."
      break
    rescue Exception => e
      puts e.message
    end
  else
    print "Skipping, file already exists."
  end

  print "\n"
  i += 1
end
