#!/usr/bin/env ruby
require 'moving_images'

include MovingImages
include MIMovie
include CommandModule

# This will double the frame rate of a movie by merging two frames for intermediate
module GettingStarted
  @@numFrames = 296

  @@localFolder = File.expand_path(File.dirname(__FILE__))
  @@movieFolder = File.join(@@localFolder, "movies")
  @@generateMovieFolder = File.join(@@localFolder, "generatedmovies")
  @@movieFilename = "Grass2Shady.mov"
  @@inputMovie = File.join(@@movieFolder, @@movieFilename)
  @@outputFilename = "DoubledFrameRate.mov"
  @@outputFile = File.join(@@generateMovieFolder, @@outputFilename)
    
  @@videotrack_id = MovieTrackIdentifier.make_movietrackid_from_mediatype(
                                                mediatype: :vide,
                                               trackindex: 0)

  @@windowsize = MIShapes.make_size(640, 360)
  @@bitmapsize = MIShapes.make_size(1280, 720)
  
  @@imageCollectionIdentifiers = [ SecureRandom.uuid, SecureRandom.uuid ]

  def self.make_videoframeswriter(commands)
    videoFramesWriter = commands.make_createvideoframeswriter(@@outputFile)
    frameDuration = MovieTime.make_movietime(timevalue: 100, timescale: 6000)
    addInputToVideoFramesWriter = CommandModule.make_addinputto_videowritercommand(
                                        videoFramesWriter,
                                preset: :h264preset_hd,
                             framesize: @@bitmapsize,
                         frameduration: frameDuration)
    commands.add_command(addInputToVideoFramesWriter)
    videoFramesWriter
  end

  def self.assign_nextvideoframe_toimagecollection(commands,
                                         importer: nil,
                                  imageidentifier: nil)
    assignFrameCommand = CommandModule.make_assignimage_frommovie_tocollection(
                              importer, frametime: MovieTime.make_movietime_nextsample,
                                           tracks: [ @@videotrack_id ],
                                       identifier: imageidentifier)
    commands.add_command(assignFrameCommand)
  end

  def self.draw_imageincollection_to_context(commands,
                                 identifier: nil,
                                       size: nil,
                                    context: nil,
                                      alpha: 1.0)
    drawImageElement = MIDrawImageElement.new
    destRect = MIShapes.make_rectangle(size: size)
    drawImageElement.destinationrectangle = destRect
    drawImageElement.contextalpha = alpha
    drawImageElement.set_imagecollection_imagesource(identifier: identifier)
    drawElementCommand = CommandModule.make_drawelement(context,
                                 drawinstructions: drawImageElement)
    commands.add_command(drawElementCommand)
  end

  def self.run()
    begin
      commands = SmigCommands.new
      movieImporter = commands.make_createmovieimporter(@@inputMovie)

      bitmap = commands.make_createbitmapcontext(size: @@bitmapsize,
                                               preset: :PlatformDefaultBitmapContext,
                                              profile: :kCGColorSpaceGenericRGB)
      videoFramesWriter = self.make_videoframeswriter(commands)
      addImageToVideoFramesWriter = CommandModule.make_addimageto_videoinputwriter(
                                          videoFramesWriter,
                            sourceobject: bitmap)

      self.assign_nextvideoframe_toimagecollection(commands,
                                   importer: movieImporter,
                            imageidentifier: @@imageCollectionIdentifiers[0])
      @@numFrames.times do |index|
        self.draw_imageincollection_to_context(commands,
                                 identifier: @@imageCollectionIdentifiers[index % 2],
                                       size: @@bitmapsize,
                                    context: bitmap)
        commands.add_command(addImageToVideoFramesWriter)

        self.assign_nextvideoframe_toimagecollection(commands,
                                     importer: movieImporter,
                              imageidentifier: @@imageCollectionIdentifiers[(index + 1) % 2])
        self.draw_imageincollection_to_context(commands,
                                 identifier: @@imageCollectionIdentifiers[(index + 1) % 2],
                                       size: @@bitmapsize,
                                    context: bitmap,
                                      alpha: 0.5)
        commands.add_command(addImageToVideoFramesWriter)
      end
      self.draw_imageincollection_to_context(commands,
                               identifier: @@imageCollectionIdentifiers[@@numFrames % 2],
                                     size: @@bitmapsize,
                                  context: bitmap)
      commands.add_command(addImageToVideoFramesWriter)
  
      finishWritingVideoCommand = CommandModule.make_finishwritingframescommand(
                                           videoFramesWriter)
      commands.add_command(finishWritingVideoCommand)
      commands.add_tocleanupcommands_removeimagefromcollection(@@imageCollectionIdentifiers[0])
      commands.add_tocleanupcommands_removeimagefromcollection(@@imageCollectionIdentifiers[1])
      theTime = Smig.perform_timed_commands(commands)
      puts "Time taken: #{theTime}"
      `open "#{@@outputFile}"`
    end
  end
end

GettingStarted.run
