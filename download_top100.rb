#!/usr/bin/env ruby

require 'xmlsimple'
require 'lib/mfm'

data = XmlSimple.xml_in File.open(ARGV[0]), {'ForceArray' => false}

MFM.init(YAML.load_file('settings.yml'))
i = 1
data['tracks']['track'].each do |t|
  track = MFM::Track.new(t)
  mp3_file = "#{track.artistname} - #{track.trackname}.mp3"
  print "Saving track ##{i} into '#{mp3_file}'... "
  unless File.exist?(mp3_file)
    begin
      track.save_as_mp3(mp3_file)
    rescue Exception => e
      puts e.message
    end
  else
    print "Skipping, file already exists."
  end

  print "\n"
  i += 1
end
