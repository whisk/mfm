#!/usr/bin/env ruby

require 'xmlsimple'
require 'lib/mfm'

data = XmlSimple.xml_in File.open(ARGV[0]), {'ForceArray' => false}

MFM.init(YAML.load_file('settings.yml'))
data['tracks']['track'].each do |t|
  track = MFM::Track.new(t)
  track.save_as_mp3("#{track.artistname} - #{track.trackname}.mp3")
end
