#!/usr/bin/env ruby
require 'moving_images'

include MovingImages
include MIMovie
include CommandModule

# This will combine two movies and join them using a ripple transition filter.
module GettingStarted
  @@displayInWindow = true

  @@movieFileName1 = "Grass2Shady.mov"
  @@movieFileName2 = "ShadyBorder.mov"
  @@movieFolder = File.expand_path(File.join(File.dirname(__FILE__), "../movies"))
  @@movieFile1 = File.join(@@movieFolder, @@movieFileName1)
  @@movieFile2 = File.join(@@movieFolder, @@movieFileName2)
  @@outputFilename = "RippleTransition.mov"
  @@exportFolder = File.join(File.expand_path(File.dirname(__FILE__)), "../generatedmovies")
  @@outputFile = File.join(exportFolder, "../generatedmovies", @@outputFilename))
  # @@outputFile = File.join(@@movieFolder, @@outputFilename)

  @@imageidentifier_video1 = SecureRandom.uuid
  @@imageidentifier_video2 = SecureRandom.uuid

  @@videotrack_id = MovieTrackIdentifier.make_movietrackid_from_mediatype(
                                                mediatype: :vide,
                                               trackindex: 0)
  @@nextframe_time = MovieTime.make_movietime_nextsample

  @@windowsize = MIShapes.make_size(640, 360)
  @@bitmapsize = MIShapes.make_size(1280, 720)
  
  module MakeFilterChain
    private
    @@radialFilterIdentifier = 'eu.zukini.movingimages.gettingstarted.radial'
    @@cropFilterIdentifier = 'eu.zukini.movingimages.gettingstarted.crop'
    @@rippleFilterIdentifier = 'eu.zukini.movingimages.gettingstarted.ripple'
    
    @@largeRadius = 200
    
    def self.make_radialgradientfilter()
      radialGradientFilter = MIFilter.new(:CIRadialGradient,
                               identifier: @@radialFilterIdentifier)
      center_property = MIFilterProperty.make_civectorproperty_fromarray(
                                      key: :inputCenter,
                                    value: [@@largeRadius, @@largeRadius])
      radialGradientFilter.add_property(center_property)
      radius0_property = MIFilterProperty.make_cinumberproperty(key: :inputRadius0,
                                                              value: 10.0)
      radialGradientFilter.add_property(radius0_property)
      radius1_property = MIFilterProperty.make_cinumberproperty(key: :inputRadius1,
                                                              value: @@largeRadius)
      radialGradientFilter.add_property(radius1_property)
      color0 = MIColor.make_rgbacolor(1, 1, 1, a: 0.0)
      color0_property = MIFilterProperty.make_cicolorproperty_fromhash(
                                                                key: :inputColor0,
                                                              value: color0)
      radialGradientFilter.add_property(color0_property)
      color1 = MIColor.make_rgbacolor(0, 0, 0, a: 0.7)
      color1_property = MIFilterProperty.make_cicolorproperty_fromhash(
                                                                key: :inputColor1,
                                                              value: color1)
      radialGradientFilter.add_property(color1_property)
      radialGradientFilter
    end
    
    def self.make_cropfilter()
      cropRect = MIShapes.make_rectangle(width: @@largeRadius * 2,
                                        height: @@largeRadius * 2)
      cropRectProperty = MIFilterProperty.make_civectorproperty_fromrectangle(
                                      key: :inputRectangle,
                                    value: cropRect)
      inputFilterID = SmigIDHash.makeid_withfilternameid(@@radialFilterIdentifier)
      inputImageProperty = MIFilterProperty.make_ciimageproperty(
                                      key: :inputImage,
                                    value: inputFilterID)
      cropFilter = MIFilter.new(:CICrop, identifier: @@cropFilterIdentifier)
      cropFilter.properties = [ cropRectProperty, inputImageProperty ]
      cropFilter
    end
    
    def self.make_rippletransitionfilter(video1identifier, video2identifier)
      # The create the ripple transition filter.
      rippleTransition = MIFilter.new(:CIRippleTransition,
                            identifier: @@rippleFilterIdentifier)
      imageSource = SmigIDHash.make_imageidentifier(video1identifier)
      rippleTransition.add_inputimage_property(imageSource)
      destImageSource = SmigIDHash.make_imageidentifier(video2identifier)
      rippleTransition.add_image_property(:inputTargetImage,
                            image_source: destImageSource)

      radialFilterSource = SmigIDHash.makeid_withfilternameid(@@cropFilterIdentifier)
      rippleTransition.add_image_property(:inputShadingImage,
                            image_source: radialFilterSource)

      extent = MIShapes.make_rectangle(width: 1280, height: 720)
      extentProperty = MIFilterProperty.make_civectorproperty_fromrectangle(
                                     key: :inputExtent,
                                   value: extent)
      rippleTransition.add_property(extentProperty)

      center = MIShapes.make_point(640, 360)
      centerProperty = MIFilterProperty.make_civectorproperty_frompoint(
                                     key: :inputCenter,
                                   value: center)
      rippleTransition.add_property(centerProperty)
      rippleTransition
    end

    public

    def self.make_transitionfilter(commands,
               render_destination: nil,
                 video1identifier: nil,
                 video2identifier: nil)
      radialGradient = self.make_radialgradientfilter()
      cropFilter = self.make_cropfilter()
      rippleTransition = self.make_rippletransitionfilter(video1identifier,
                                                          video2identifier)
      filterChain = MIFilterChain.new(render_destination,
                          filterList: [ radialGradient.filterhash,
                                            cropFilter.filterhash,
                                      rippleTransition.filterhash])
      filterChainObject = commands.make_createimagefilterchain(filterChain)
      filterChainObject
    end
    
    def self.render_rippletranstion(filterChainObj, time: nil)
        renderProp = MIFilterRenderProperty.make_renderproperty_withfilternameid(
                                    key: :inputTime,
                                  value: time,
                          filtername_id: @@rippleFilterIdentifier)
        renderInstructions = MIFilterChainRender.new
        renderInstructions.add_filterproperty(renderProp)
        renderInstructions.sourcerectangle = MIShapes.make_rectangle(width: 1280,
                                                                    height: 720)
        renderCommand = CommandModule.make_renderfilterchain(filterChainObj,
                                          renderinstructions: renderInstructions)
        renderCommand
    end
    
  end
  
  def self.assign_nextvideoframe_toimagecollection(commands,
                                         importer: nil,
                                  imageidentifier: nil)
    assignFrameCommand = CommandModule.make_assignimage_frommovie_tocollection(
                              importer, frametime: @@nextframe_time,
                                           tracks: [ @@videotrack_id ],
                                       identifier: imageidentifier)
    commands.add_command(assignFrameCommand)
  end

  def self.draw_imageincollection_to_context(commands,
                                 identifier: nil,
                                       size: nil,
                                    context: nil)
    drawImageElement = MIDrawImageElement.new
    destRect = MIShapes.make_rectangle(size: size)
    drawImageElement.destinationrectangle = destRect
    drawImageElement.set_imagecollection_imagesource(identifier: identifier)
    drawElementCommand = CommandModule.make_drawelement(context,
                                 drawinstructions: drawImageElement)
    commands.add_command(drawElementCommand)
  end

  def self.draw_bitmap_towindow(commands, bitmap: nil, window: nil)
    drawImageElement = MIDrawImageElement.new
    winRect = MIShapes.make_rectangle(size: @@windowsize)
    drawImageElement.destinationrectangle = winRect
    drawImageElement.set_bitmap_imagesource(source_object: bitmap)
    drawElementCommand = CommandModule.make_drawelement(window,
                                 drawinstructions: drawImageElement)
    commands.add_command(drawElementCommand)
  end

  def self.make_videoframeswriter(commands)
    videoFramesWriter = commands.make_createvideoframeswriter(@@outputFile)
    frameDuration = MovieTime.make_movietime(timevalue: 20, timescale: 600)
    addInputToVideoFramesWriter = CommandModule.make_addinputto_videowritercommand(
                                        videoFramesWriter,
                                preset: :h264preset_hd,
                             framesize: @@bitmapsize,
                         frameduration: frameDuration)
    commands.add_command(addInputToVideoFramesWriter)
    videoFramesWriter
  end

  def self.run()
    begin
      commands = SmigCommands.new
      movieImporter1 = commands.make_createmovieimporter(@@movieFile1)
      movieImporter2 = commands.make_createmovieimporter(@@movieFile2)
      
      if @@displayInWindow
        windowRect = MIShapes.make_rectangle(xloc: 40, yloc: 80, size: @@windowsize)
        window = commands.make_createwindowcontext(rect: windowRect)
      end

      bitmap = commands.make_createbitmapcontext(size: @@bitmapsize,
                                               preset: :PlatformDefaultBitmapContext,
                                              profile: :kCGColorSpaceGenericRGB)
      filterChain = MakeFilterChain.make_transitionfilter(commands,
                                   render_destination: bitmap,
                                     video1identifier: @@imageidentifier_video1,
                                     video2identifier: @@imageidentifier_video2)
      
      videoFramesWriter = self.make_videoframeswriter(commands)

      addImageToVideoFramesWriter1 = CommandModule.make_addimageto_videoinputwriter(
                                                videoFramesWriter,
                     imagecollectionidentifier: @@imageidentifier_video1)
      152.times do |index|
        self.assign_nextvideoframe_toimagecollection(commands,
                                             importer: movieImporter1,
                                      imageidentifier: @@imageidentifier_video1)
        commands.add_command(addImageToVideoFramesWriter1)
        if @@displayInWindow
          self.draw_imageincollection_to_context(commands,
                                   identifier: @@imageidentifier_video1,
                                         size: @@windowsize,
                                      context: window)
        end
      end

      transitionFrames = 146
      fraction = 1.0 / (transitionFrames - 1.0)
      addImageToVideoFramesWriter2 = CommandModule.make_addimageto_videoinputwriter(
                                                videoFramesWriter,
                                  sourceobject: bitmap)
      transitionFrames.times do |index|
        self.assign_nextvideoframe_toimagecollection(commands,
                                             importer: movieImporter1,
                                      imageidentifier: @@imageidentifier_video1)
        self.assign_nextvideoframe_toimagecollection(commands,
                                             importer: movieImporter2,
                                      imageidentifier: @@imageidentifier_video2)
        renderCommand = MakeFilterChain.render_rippletranstion(filterChain,
                                                         time: index.to_f * fraction)
        commands.add_command(renderCommand)
        commands.add_command(addImageToVideoFramesWriter2)
        if @@displayInWindow
          self.draw_bitmap_towindow(commands, bitmap: bitmap, window: window)
        end
      end

      addImageToVideoFramesWriter3 = CommandModule.make_addimageto_videoinputwriter(
                                                videoFramesWriter,
                     imagecollectionidentifier: @@imageidentifier_video2)
      152.times do |index|
        self.assign_nextvideoframe_toimagecollection(commands,
                                           importer: movieImporter2,
                                    imageidentifier: @@imageidentifier_video2)
        commands.add_command(addImageToVideoFramesWriter3)
        if @@displayInWindow
          self.draw_imageincollection_to_context(commands,
                                   identifier: @@imageidentifier_video2,
                                         size: @@windowsize,
                                      context: window)
        end
      end
      finishWritingVideoCommand = CommandModule.make_finishwritingframescommand(
                                             videoFramesWriter)
      commands.add_command(finishWritingVideoCommand)
      commands.add_tocleanupcommands_removeimagefromcollection(@@imageidentifier_video1)
      commands.add_tocleanupcommands_removeimagefromcollection(@@imageidentifier_video2)
      theTime = Smig.perform_timed_commands(commands)
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

GettingStarted.run
