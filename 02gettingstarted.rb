#!/usr/bin/env ruby
require 'moving_images'

include MovingImages
include MIMovie
include CommandModule

module GettingStarted
  def self.make_getvideotrackproperties_command(movieImporter)
    track = MovieTrackIdentifier.make_movietrackid_from_mediatype(
                                                mediatype: :vide,
                                               trackindex: 0)
    
    getPropertiesCommand = CommandModule.make_get_objectproperties(movieImporter,
                                      saveresultstype: :jsonstring)
    getPropertiesCommand.add_option(key: :track, value: track)
    getPropertiesCommand
  end

  def self.run()
    movieFile = MILibrary::Utility.request_a_file()
    puts movieFile
    puts "========================================================"
    commands = SmigCommands.new
    movieImporter = commands.make_createmovieimporter(movieFile)
    getPropertiesCommand = self.make_getvideotrackproperties_command(movieImporter)
    commands.add_command(getPropertiesCommand)
    puts JSON.pretty_generate(commands.commandshash)
    puts "========================================================"
    jsonText = Smig.perform_commands(commands)
    jsonHash = JSON.parse(jsonText)
    puts JSON.pretty_generate(jsonHash)
    # Smig.close_object_nothrow(movieImporter)
  end
end

GettingStarted.run
