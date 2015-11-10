#!/usr/bin/env ruby
require 'moving_images'

include MovingImages
include CommandModule

module GettingStarted
  def self.create_window()
    windowName = SecureRandom.uuid
    window = SmigIDHash.make_objectid(objectname: windowName,
                                      objecttype: :nsgraphicscontext)
    createWindowCommand = CommandModule.make_createwindowcontext(name: windowName)
    puts JSON.pretty_generate(createWindowCommand.commandhash)
    Smig.perform_command(createWindowCommand)
    window
  end

  def self.run()
    theWindow = self.create_window()
    sleep 2
    closeCommand = CommandModule.make_close(theWindow)
    Smig.perform_command(closeCommand)
    puts JSON.pretty_generate(closeCommand.commandhash)
  end
end

GettingStarted.run
