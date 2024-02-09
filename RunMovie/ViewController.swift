//
//  ViewController.swift
//  RunMovie
//
//  Created by peterappleby on 2/28/22.
//

import Cocoa
import AVKit
import AVFoundation
import Carbon.HIToolbox

// import Network
import Combine

public class ViewController: NSViewController {
    @IBOutlet weak var playerView: AVPlayerView!
    
    var listener: UDPListener!
    
    var subscription: AnyCancellable?
    
    var portReq: String = ""
    
        // var player: AVPlayer!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
            // Do any additional setup after loading the view.
        
        Globals.logger.log("*** In ViewController viewDidLoad")
        
        Globals.viewController = self
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            if self.myKeyDown(with: $0) {
                return nil
            } else {
                return $0
            }
        }
               
        var c = 0
        for arg in CommandLine.arguments {
            Globals.logger.log("argument \(c, privacy: .public) is: \(arg, privacy: .public)")
            c += 1
        }
        
        let saveDefaultMovieFile: Bool = true
        let fileMgr = FileManager()
        var isDir : ObjCBool = true
        
        let programPath = Bundle.main.executablePath
        
        let programName1 = "RunMovie.app"
        let programName2 = "RunMovie2.app"
        let programName3 = "RunMovie3.app"
        
        var displayName = ""
        var suffix = ""
        var channelListenString = ""
       
        if programPath!.localizedCaseInsensitiveContains(programName1)
        {
            displayName = "Blackmagic (1)"
            channelListen = channelA
            channelListenString = "A"
        }
        else if programPath!.localizedCaseInsensitiveContains(programName2)
        {
            suffix = "2"
            displayName = "Blackmagic (2)"
            channelListen = channelB
            channelListenString = "B"
        }
        else if programPath!.localizedCaseInsensitiveContains(programName3)
        {
            suffix = "3"
            displayName = "Blackmagic (3)"
            channelListen = channelC
            channelListenString = "C"
        }
        else
        {
            displayName = "Blackmagic (1)"
            channelListen = channelA
            channelListenString = UserDefaults.standard.string(forKey: "MidiChannel") ?? "A"
        }
        
        let movieKeyName = "MovieFileOpenPath" + suffix
        let midiKeyName = "MidiChannel" + suffix
        
        Globals.logger.log("*** In ViewController viewDidLoad - movieKeyName =  \(movieKeyName, privacy: .public)")
        Globals.logger.log("*** In ViewController viewDidLoad - midiKeyName =  \(midiKeyName, privacy: .public)")

      
        var path  = UserDefaults.standard.string(forKey: movieKeyName)
        if ( path != nil && path?.isEmpty == false )
        {
            Globals.logger.log("*** In ViewController viewDidLoad - default movie =  \(path!, privacy: .public)")
            
            if ( fileMgr.fileExists(atPath: path!, isDirectory:  &isDir) == true )
            {
                Globals.movieFilepath = path!
            }
            else
            {
                // saveDefaultMovieFile = false
            }
        }
        
        // channelListen = channelA

        let saveDefaultChannel: Bool = true
        
        if ( channelListenString != "" )            // pma 1/23/2024
        {
            Globals.logger.log("*** In ViewController viewDidLoad 1 - default MIDI channel =  \(channelListenString, privacy: .public)")
            
            if ( channelListenString == "A" )
            {
                channelListen = channelA
                displayName = "Blackmagic (1)"
            }
            else if ( channelListenString == "B")
            {
                channelListen = channelB
                displayName = "Blackmagic (2)"
            }
            else if ( channelListenString == "C")
            {
                channelListen = channelC
                displayName = "Blackmagic (3)"
            }
            /*
            else
            {
                saveDefaultChannel = false
                channelListen = channelA
                channelListenString = "A"
            }
             */
        }
        /*
        else
        {
            channelListenString = "A"
        }
         */
        
        Globals.logger.log("*** In ViewController viewDidLoad 1 - current MIDI channel =  \(channelListenString, privacy: .public)")
        
        if CommandLine.argc >= 2 && CommandLine.arguments[1] != "-NSDocumentRevisionsDebugMode"
        {
            // saveDefaultMovieFile = false
            
            path = CommandLine.arguments[1]
            Globals.movieFilepath = path!
            
            if ( fileMgr.fileExists(atPath: path!, isDirectory:  &isDir) == true )
            {
                // saveDefaultMovieFile = true
            }

            
            if CommandLine.argc >= 3
            {
                Globals.logger.log("*** In ViewController viewDidLoad 2 - current MIDI channel =  \(channelListenString, privacy: .public)")
                
                // saveDefaultChannel = false
                
                portReq = CommandLine.arguments[2]
                
                channelListenString = portReq
                
                if ( portReq == "A" )
                {
                    // Globals.port = Globals.portA
                    channelListen = channelA
                    channelListenString = "A"
                    displayName = "Blackmagic (1)"
                }
                else if ( portReq == "B")
                {
                    // Globals.port = Globals.portB
                    channelListen = channelB
                    channelListenString = "B"
                    displayName = "Blackmagic (2)"
                }
                else if ( portReq == "C")
                {
                    // Globals.port = Globals.portC
                    channelListen = channelC
                    channelListenString = "C"
                    displayName = "Blackmagic (3)"
                }
                
                /*
                else
                {
                    channelListen = channelA
                    channelListenString = "A"
                }
                */
                
            }
        }
        
        /*
        else if CommandLine.argc >= 1
        {
            Globals.movieFilepath = CommandLine.arguments[0]
        }
        */
        
        Globals.logger.log("*** In ViewController viewDidLoad 3 - current MIDI channel =  \(channelListenString, privacy: .public)")
        
        if saveDefaultMovieFile == true
        {
            Globals.logger.log("*** In ViewController viewDidLoad - saving new default movie =  \(Globals.movieFilepath, privacy: .public)")
            UserDefaults.standard.set( Globals.movieFilepath, forKey: movieKeyName)
        }
        
        if saveDefaultChannel == true
        {
            Globals.logger.log("*** In ViewController viewDidLoad - saving new default MIDI channel =  \(channelListenString, privacy: .public)")
            UserDefaults.standard.set( channelListenString, forKey: midiKeyName)
        }
        
        
        let tempChannel = channelListen + 1     // MIDI Channel data is from 0x00 to 0x0F, but the channels are named one through fifteen
        
        Globals.logger.log("*** In ViewController viewDidLoad - MIDI Channel =  \(tempChannel, privacy: .public)")
        
        // Globals.logger.log("*** In ViewController viewDidLoad - UDP Port =  \(Globals.port.debugDescription, privacy: .public)")
        
        Globals.logger.log("*** In ViewController viewDidLoad - movieFilepath =  \(Globals.movieFilepath, privacy: .public)")
        
        // See if we need to move the app window to another screen (display)
        
        Globals.mainScreenName = NSScreen.screens[0].localizedName      // always the main display
        
        /*
         screen 0 is: PHL 346E2C
         screen 1 is: Blackmagic (2)
         screen 2 is: Blackmagic (1)
         screen 3 is: Blackmagic (3)
         */
        
        c = 0
        for screen in NSScreen.screens {
            
            let name = screen.localizedName
            
            Globals.logger.log("screen \(c) is: \(name, privacy: .public)")
            
            if name == displayName
            {
                Globals.targetScreen = screen
            }
            
            c += 1
        }
        
        let url = URL(fileURLWithPath: Globals.movieFilepath)
        
        Globals.movieFileURL = url
        
            //
        
        let asset =   AVAsset(url: url)
        
        let assetKeys = [
            "playable",
            "hasProtectedContent"
        ]
        
            // Create a new AVPlayerItem with the asset and an
            // array of asset keys to be automatically loaded
        
        Globals.logger.log("*** In ViewController viewDidLoad - creating playerItem")
        
        Globals.playerItem = AVPlayerItem(asset: asset,
                                  automaticallyLoadedAssetKeys: assetKeys)
        
            // Register as an observer of the player item's status property
        
        /*
         playerItem.addObserver(self,
         forKeyPath: #keyPath(AVPlayerItem.status),
         options: [.old, .new],
         context: &playerItemContext)
         */
        
            // Associate the player item with the player
        
        Globals.logger.log("*** In ViewController viewDidLoad - create an AVPlayer bound to the player item")
        
        Globals.player =   AVPlayer(playerItem: Globals.playerItem)
        
        if Globals.player.error != nil {
            let emsg = Globals.player.error?.localizedDescription
            Globals.logger.log("*** In ViewController viewDidLoad - player.error  \(emsg ?? "?" , privacy: .public)")
        }
        
        Globals.player.isMuted = true                                       // pma 1/23/2024
        Globals.player.automaticallyWaitsToMinimizeStalling = false         // pma 1/23/2024
        
        Globals.logger.log("*** In ViewController viewDidLoad - set playerView.videoGravity")
        
        self.playerView.videoGravity = .resizeAspectFill
        
        Globals.logger.log("*** In ViewController viewDidLoad - set playerView.player")
        
        playerView.player = Globals.player
        
        playerView.player?.pause()
        
        /*
            This is now setup in play() and playInToOut() below
         
        // loop video. there is a small delay :(
        
        Globals.logger.log("*** In ViewController viewDidLoad - set player observer")
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { notification in
            Globals.logger.log("*** In ViewController player observer invoke seek to zero, play")
            Globals.player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            Globals.player.play()
        }
        */
        
        Globals.logger.log("*** In ViewController viewDidLoad - set player preventsDisplaySleepDuringVideoPlayback")
        
        Globals.player.preventsDisplaySleepDuringVideoPlayback = true
        
        clearBothMarks()
        
        /*
            Removed UDP stuff, now using MIDI and keyboard
         
        Globals.logger.log("*** In ViewController viewDidLoad - creating UDPListener")
        
        listener = UDPListener(on: Globals.port!)
        
        subscription = listener.$messageReceived.sink(receiveValue: { msgData in
            
            let str = String(decoding: msgData ?? Data(), as: UTF8.self)
            print("*** In ViewController viewDidLoad $messageReceived sink \(str)")
            
            let intKeyCode = Int.init(str)
            _ = self.handleKeyPress(keyCode: intKeyCode ?? 0)
        })
        */
        
        Globals.logger.log("*** In ViewController viewDidLoad - get MIDI info")
        
        getMIDINames()
        
        MIDIClientCreate("RunMovie" as CFString, nil, nil, &midiClient)
        
        MIDIInputPortCreate(midiClient, "RunMovie_InPort" as CFString, MyMIDIReadProc, nil, &midiInPort)
        
        MIDIPortConnectSource(midiInPort, midiSrc, &midiSrc)
        
        Globals.logger.log("*** In ViewController viewDidLoad - open workspace")
        
        openWorkspace()
        
        Globals.logger.log("*** In ViewController viewDidLoad - viewDidLoad completed")
    }
    
    
    func handleKeyPress( keyCode: Int ) -> Bool
    {
        switch Int( keyCode) {
                
            case kVK_Escape:          // Toggle Full Screen
                
                Globals.logger.log("*** In ViewController handleKeyPress for <Esc>  - setting toggleFullScreen(true)")
                
                NSApplication.shared.mainWindow?.toggleFullScreen(true)
                
                return true
                
                
            case kVK_ANSI_P:          // Play player
                
                play()
                
                return true
                
            case kVK_ANSI_Q:          // Quit player
                
                Globals.logger.log("*** In ViewController handleKeyPress for <Esc>  - invoking terminate(self)")
                
                NSApplication.shared.terminate(self)
                
                return true
                
            case kVK_ANSI_R:          // Rewind player

                goToBegin()
               
                return true
                
            case kVK_ANSI_S, kVK_Space: // Stop player
                              
                pause()
                savePosition()
                
                return true
                
            case kVK_LeftArrow:       // backward one frame
                
                pause()
                Globals.playerItem?.step(byCount: -1)
                savePosition()
                
                return true
                
            case kVK_RightArrow:      // forward one frame
                
                pause()
                Globals.playerItem?.step(byCount: 1)
                savePosition()
                
                return true
                
            // Function keys same as MIDI keys!
                
            case kVK_F2:
            
                // rewind aka go to start
                    
                goToBegin()
                
                return true
                
            case kVK_F3:      // pause
                
                pause()
                
                return true
                
            case kVK_F4:      // play
                
                play()
                
                return true
                
            case kVK_F5:      // play in to out
                
                playInToOut()
                
                return true

            case kVK_F6:       // go to end
                
                goToEnd()
                
                return true
                
            case kVK_F7:
                
                // Go To In mark
                
                goToMarkIn()

                return true
                
            case kVK_F8:
                
                // Go To Out mark
                
                goToMarkOut()

                return true
                
            case kVK_F9:
                
                // Mark In
                
                setMarkIn()

                return true
             
            case kVK_F10:
                
                // Mark Out
                
                setMarkOut()
                
                return true
                
            case kVK_F11:
            
                // clear In mark
                
                clearMarkIn()
                
                return true
                
            case kVK_F12:
                
                // clear Out mark
                
                clearMarkOut()

                return true

            case kVK_ANSI_Period:
                
                // screen shot
                
                exportScreenShot()
                
                return true
                
            default:
                Globals.logger.log("*** In ViewController handleKeyPress - unrecognized key code =  \(keyCode, privacy: .public)")
                
                return false
        }
    }
    
    func myKeyDown(with event: NSEvent) -> Bool {
        
            // handle keyDown only if current window has focus, i.e. is keyWindow
        
        guard let locWindow = self.view.window,
              NSApplication.shared.keyWindow === locWindow else { return false }
        
        let keyCode = Int( event.keyCode )
        
        let result = handleKeyPress( keyCode: keyCode)
        
        return result
        
    }
    
    public override var representedObject: Any? {
        didSet {
                // Update the view, if already loaded.
        }
    }
    
    public func rewind()
    {
        pause()
        goToBegin()
    }
    
    public func play()
    {
        pause()
        
        NotificationCenter.default.removeObserver(self)
        
        Globals.player?.actionAtItemEnd = .none
            NotificationCenter.default.addObserver(self,
                selector: #selector(self.playerItemDidReachEnd),
                 name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                 object: Globals.player?.currentItem)

        Globals.player?.currentItem!.reversePlaybackEndTime =  CMTime.zero
        Globals.player?.currentItem!.forwardPlaybackEndTime =  Globals.playerItem.asset.duration
        
        Globals.player!.rate = playbackRate
    }
    
    @objc func playerItemDidReachEnd(notification: NSNotification) {
               
        if let playerItem: AVPlayerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
    
    public func playInToOut()
    {
        Globals.player!.pause()
        goToMarkIn()
        
        NotificationCenter.default.removeObserver(self)
        
        Globals.player?.actionAtItemEnd = .none
            NotificationCenter.default.addObserver(self,
                selector: #selector(self.playerItemDidReachMarkOut),
                 name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                 object: Globals.player?.currentItem)

        
        Globals.player?.currentItem!.reversePlaybackEndTime =  markIn
        Globals.player?.currentItem!.forwardPlaybackEndTime =  markOut
        
        Globals.player!.rate = playbackRate
        
        savePosition()
    }

    @objc func playerItemDidReachMarkOut(notification: NSNotification) {
               
        if let playerItem: AVPlayerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: markIn, completionHandler: nil)
        }
    }
    
    public func reset()
    {
        pause()
        playbackRate = 1.0      // Normal speed the next time Play is requested
        clearBothMarks()
    }

    public func pause()
    {
        Globals.player!.pause()
        
        savePosition()
    }
    
    public func goToBegin()
    {
        pause()
        
        Globals.player!.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        
        savePosition()
    }
    
    public func goToEnd()
    {
        pause()
        
        let endOfMovie = Globals.playerItem.asset.duration
        Globals.player!.seek(to: endOfMovie, toleranceBefore: .zero, toleranceAfter: .zero)
        
        savePosition()
    }
    
    public func goToMarkIn()
    {
        pause()
        
        Globals.player.seek(to: markIn, toleranceBefore: .zero, toleranceAfter: .zero)
        
        savePosition()
    }
    
    public func goToMarkOut()
    {
        pause()
        
        Globals.player.seek(to: markOut, toleranceBefore: .zero, toleranceAfter: .zero)
        
        savePosition()
    }
    
    public func setMarkIn()
    {
        markIn = Globals.player.currentTime()
        Globals.workspace.markIn = markIn.value
        saveWorkspace()
    }
    
    public func setMarkOut()
    {
        markOut = Globals.player.currentTime()
        Globals.workspace.markOut = markOut.value
        saveWorkspace()
    }
    
    public func clearMarkIn()
    {
        markIn = CMTime.zero
        Globals.workspace.markIn = markIn.value
        saveWorkspace()
    }
    
    public func clearMarkOut()
    {
        markOut = Globals.playerItem.asset.duration
        Globals.workspace.markOut = markOut.value
        saveWorkspace()
    }
    
    public func clearBothMarks()
    {
        clearMarkIn()
        clearMarkOut()
    }
    
    public func exportScreenShot() {

        /*
              let asset = AVAsset(url: videoURL)
              let generator = AVAssetImageGenerator.init(asset: asset)
              let cgImage = try! generator.copyCGImage(at: CMTime (0, 1), actualTime: nil)
              firstFrame.image = UIImage(cgImage: cgImage) //firstFrame is UIImage in table cell
         
         */
        
        let time = Globals.player.currentTime()
        
        let asset = AVAsset(url: Globals.movieFileURL)
        
        let generator = AVAssetImageGenerator.init(asset: asset)
        
        let cgImage = try! generator.copyCGImage(at: time, actualTime: nil)
        
        let nsImage = NSImage(cgImage: cgImage, size: .zero)
        
        let directoryURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
        
        var fn = Globals.movieFileURL.deletingPathExtension().lastPathComponent
        
        let formatter = DateFormatter()
        formatter.dateFormat = ".yyyyMMdd.HHmmss"
        let dateTime = formatter.string(from: Date.now)
               
        fn += dateTime
        
        let fileURL = URL(fileURLWithPath: fn, relativeTo: directoryURL).appendingPathExtension("png")
        
        // save the image to the url
        
        if nsImage.pngWrite(to: fileURL )
        {
            NSLog("Screen shot export successful")
        }
        else
        {
            NSLog("Screen shot export FAILED")
        }
    }
    
    public func openWorkspace()
    {
        let path = Globals.movieFileURL.path
        
        let url = NSURL(fileURLWithPath: path).deletingPathExtension?.appendingPathExtension("json") // change extension to .json
        
        Globals.workspaceFilepath = url?.path ?? ""
        
        let temp = JsonHandler.readJSON(object: Workspace.self, url: url  )
        
        if ( temp == nil )
        {
            // create a new workspace file
            saveWorkspace() // save it!
        }
        else
        {
            let markInTemp = CMTime(value: temp!.markIn, timescale: 1000, flags: .valid, epoch: 0)
            Globals.setMarkIn(startTime: markInTemp)
            
            let markOutTemp = CMTime(value: temp!.markOut, timescale: 1000, flags: .valid, epoch: 0)
            Globals.setMarkOut(endTime: markOutTemp)
            
            markIn = markInTemp
            markOut = markOutTemp
            
            /*
            let currentTemp = CMTime(value: temp!.currentTime, timescale: 1000, flags: .valid, epoch: 0)
            Globals.player.seek(to: currentTemp, toleranceBefore: .zero, toleranceAfter: .zero)
            */
            
            Globals.workspace = temp!
        }
        
    }
    
    public func saveWorkspace()
    {
       
        if Globals.workspaceFilepath != "" && Globals.windowWasLoaded == true
        {
            
            // Globals.workspace.currentTime = Globals.player.currentTime().value
            
            let url =  URL(fileURLWithPath: Globals.workspaceFilepath, isDirectory: false  )
            
            JsonHandler.writeJSON(object: Globals.workspace, url: url)
        }
    }
    
    
    public func savePosition() 
    {

        if Globals.workspaceFilepath != "" && Globals.windowWasLoaded == true
        {
            let currentTime = Globals.player.currentTime()
            
            Globals.workspace.currentTime = currentTime.value
            
            saveWorkspace()
        }

    }
}
