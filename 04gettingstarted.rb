#!/usr/bin/env ruby

require 'moving_images'

include MovingImages
include MICGDrawing
include CommandModule
include MIMovie

# This will draw some info text in bottom left corner.
class DrawTextOnVideoFrames
  @@numFrames = 300

  @@localFolder = File.expand_path(File.dirname(__FILE__))
  @@movieFolder = File.join(@@localFolder, "movies")
  @@generatedMovieFolder = File.join(@@localFolder, "generatedmovies")
  @@movieFilename = "IMG_0874.MOV"
  @@inputMovie = File.join(@@movieFolder, @@movieFilename)
  @@outputFilename = "SheffieldRuby.mov"
  @@outputFile = File.join(@@generatedMovieFolder, @@outputFilename)

  @@textBitmapWidth = 300
  @@textBitmapHeight = 150
  @@videoWidth = 1280
  @@videoHeight = 720
  
  def self.drawto_textbitmap(text1: nil, text2: nil, bitmap: nil)
    drawArrayOfElements = MIDrawElement.new(:arrayofelements)
    borderWidth = 6

    drawText1Background = MIDrawElement.new(:fillrectangle)
    text2BackgroundRect = MIShapes.make_rectangle(xloc: borderWidth,
                                                  yloc: borderWidth,
                                                 width: @@textBitmapWidth - 2 * borderWidth,
                                                height: @@textBitmapHeight * 0.5 - 2 * borderWidth)
    text1BackgroundRect = MIShapes.make_rectangle(xloc: borderWidth,
                                                  yloc: @@textBitmapHeight * 0.5,
                                                 width: @@textBitmapWidth - 2 * borderWidth,
                                                height: @@textBitmapHeight * 0.5 - borderWidth)
    textBox1 = MIShapes.make_rectangle(xloc: borderWidth,
                                   yloc: @@textBitmapHeight * 0.5,
                                  width: @@textBitmapWidth - 2 * borderWidth,
                                 height: @@textBitmapHeight * 0.5 - 2 * borderWidth)
    textBox2 = MIShapes.make_rectangle(xloc: borderWidth,
                                       yloc: 0,
                                      width: @@textBitmapWidth - 2 * borderWidth,
                                     height: @@textBitmapHeight * 0.5 - 2 * borderWidth)

    drawText1Background.rectangle = text1BackgroundRect
    drawText1Background.fillcolor = MIColor.make_rgbacolor(0,0,0, a: 1.0)
    drawText1Background.blendmode = :kCGBlendModeCopy
    drawArrayOfElements.add_drawelement_toarrayofelements(drawText1Background)
    
    drawStringElement1 = MIDrawBasicStringElement.new
    drawStringElement1.boundingbox = textBox1
    drawStringElement1.fontsize = 44
    drawStringElement1.fillcolor = MIColor.make_rgbacolor(0.5,0.5,0.5, a: 0.0)
    drawStringElement1.blendmode = :kCGBlendModeCopy
    drawStringElement1.stringtext = text1
    drawStringElement1.postscriptfontname = :'Tahoma-Bold'
    drawStringElement1.textalignment = :kCTTextAlignmentCenter
    drawArrayOfElements.add_drawelement_toarrayofelements(drawStringElement1)

    drawText2Background = MIDrawElement.new(:fillrectangle)
    drawText2Background.rectangle = text2BackgroundRect
    drawText2Background.fillcolor = MIColor.make_rgbacolor(0.5,0.5,0.5, a: 0.0)
    drawText2Background.blendmode = :kCGBlendModeCopy
    drawArrayOfElements.add_drawelement_toarrayofelements(drawText2Background)
    
    drawStringElement2 = MIDrawBasicStringElement.new
    drawStringElement2.boundingbox = textBox2
    drawStringElement2.fontsize = 40
    drawStringElement2.fillcolor = MIColor.make_rgbacolor(1.0,1.0,1.0, a: 1.0)
    drawStringElement2.blendmode = :kCGBlendModeCopy
    drawStringElement2.stringtext = text2
    drawStringElement2.postscriptfontname = :'Tahoma-Bold'
    drawStringElement2.textalignment = :kCTTextAlignmentCenter
    drawArrayOfElements.add_drawelement_toarrayofelements(drawStringElement2)
    
    drawElementCommand = CommandModule.make_drawelement(bitmap, drawinstructions: drawArrayOfElements)
    drawElementCommand
  end

  def self.draw_textbitmap(videoFrameBitmap, textbitmap: nil)
    drawTextBitmap = MIDrawImageElement.new
    drawTextBitmap.set_bitmap_imagesource(source_object: textbitmap)
    destRect = MIShapes.make_rectangle(xloc: 100,
                                       yloc: 50,
                                      width: @@textBitmapWidth,
                                     height: @@textBitmapHeight)
    drawTextBitmap.destinationrectangle = destRect
    drawElementCommand = CommandModule.make_drawelement(videoFrameBitmap, drawinstructions: drawTextBitmap)
    drawElementCommand
  end

  def self.draw_videoframe(videoImporter, videobitmap: nil)
    nextFrameTime = MovieTime.make_movietime_nextsample
    drawVideoFrameBitmap = MIDrawImageElement.new
    drawVideoFrameBitmap.set_moviefile_imagesource(source_object: videoImporter,
                                                       frametime: nextFrameTime)
    drawVideoFrameBitmap.destinationrectangle = MIShapes.make_rectangle(width: @@videoWidth, height: @@videoHeight)
    drawVideoFrameCommand = CommandModule.make_drawelement(videobitmap, drawinstructions: drawVideoFrameBitmap)
    drawVideoFrameCommand
  end

  def self.make_drawtext_on_videoframes_commands()
    texts = ["Garden", "Crocosmia", "Grape Vine", "Green"]
    textBitmapSize = MIShapes.make_size(@@textBitmapWidth, @@textBitmapHeight)
    videoFrameSize = MIShapes.make_size(@@videoWidth, @@videoHeight)
    
    frameDuration = MIMovie::MovieTime.make_movietime(timevalue: 1, timescale: 30)
    
    theCommands = SmigCommands.new
    textBitmap = theCommands.make_createbitmapcontext(size: textBitmapSize)
    videoFrameBitmap = theCommands.make_createbitmapcontext(size: videoFrameSize)
    
    movieImporter = theCommands.make_createmovieimporter(@@inputMovie)
    
    videoFramesWriter = theCommands.make_createvideoframeswriter(@@outputFile)
    addVideoInputCommand = CommandModule.make_addinputto_videowritercommand(
                                                              videoFramesWriter,
                                                   framesize: videoFrameSize,
                                               frameduration: frameDuration)
    theCommands.add_command(addVideoInputCommand)
    JSON.pretty_generate(theCommands.commandshash)
    @@numFrames.times do |index|
      drawVideoFrameCommand = self.draw_videoframe(movieImporter, videobitmap: videoFrameBitmap)
      theCommands.add_command(drawVideoFrameCommand)
      text2 = texts[index * texts.size / @@numFrames]
      drawTextCommand = self.drawto_textbitmap(text1: "Sheffield", text2: text2, bitmap: textBitmap)
      theCommands.add_command(drawTextCommand)
      drawTextBitmapToVideoFrameCommand = self.draw_textbitmap(videoFrameBitmap, textbitmap: textBitmap)
      theCommands.add_command(drawTextBitmapToVideoFrameCommand)
      addImageToWriterInput = CommandModule.make_addimageto_videoinputwriter(
          videoFramesWriter, sourceobject: videoFrameBitmap)
      theCommands.add_command(addImageToWriterInput)
    end
    finalize = CommandModule.make_finishwritingframescommand(videoFramesWriter)
    theCommands.add_command(finalize)
    theCommands
  end
  
  def self.run()
    begin
      theCommands = self.make_drawtext_on_videoframes_commands()
      # puts JSON.pretty_generate(theCommands.commandshash)
      theTime = Smig.perform_timed_commands(theCommands)
      puts "Time taken: #{theTime}"
      `open "#{@@outputFile}"`
    rescue RuntimeError => e
      unless Smig.exitvalue.zero?
        puts "Exit string: #{Smig.exitstring}"
        puts "Exit status: #{Smig.exitvalue}"
      end
      puts e.message
      puts e.backtrace.to_s
    end
  end
end

DrawTextOnVideoFrames.run()
