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
        
        channelListen = channel11
        
        if CommandLine.argc >= 2
        {
            Globals.movieFilepath = CommandLine.arguments[1]
            
            if CommandLine.argc >= 2
            {
                portReq = CommandLine.arguments[2]
                if ( portReq == "A" )
                {
                    // Globals.port = Globals.portA
                    channelListen = channel11
                }
                else if ( portReq == "B")
                {
                    // Globals.port = Globals.portB
                    channelListen = channel12
                }
            }
        }
        else if CommandLine.argc >= 1
        {
            Globals.movieFilepath = CommandLine.arguments[0]
        }
        
        let tempChannel = channelListen + 1     // MIDI Channel data is from 0x00 to 0x0F, but the channels are named one through fifteen
        
        Globals.logger.log("*** In ViewController viewDidLoad - MIDI Channel =  \(tempChannel, privacy: .public)")
        
        // Globals.logger.log("*** In ViewController viewDidLoad - UDP Port =  \(Globals.port.debugDescription, privacy: .public)")
        
        Globals.logger.log("*** In ViewController viewDidLoad - movieFilepath =  \(Globals.movieFilepath, privacy: .public)")
        
        
        Globals.mainScreenName = NSScreen.screens[0].localizedName      // always the main display
        
        c = 0
        for screen in NSScreen.screens {
            Globals.logger.log("screen \(c) is: \(screen.localizedName, privacy: .public)")
            c += 1
        }
        
        let url = URL(fileURLWithPath: Globals.movieFilepath)
        
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
        
        Globals.logger.log("*** In ViewController viewDidLoad - set playerView.videoGravity")
        
        self.playerView.videoGravity = .resizeAspectFill
        
        Globals.logger.log("*** In ViewController viewDidLoad - set playerView.player")
        
        playerView.player = Globals.player
        
        
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
                
                return true
                
            case kVK_LeftArrow:       // backward one frame
                
                pause()
                Globals.playerItem?.step(byCount: -1)
                
                return true
                
            case kVK_RightArrow:      // forward one frame
                
                pause()
                Globals.playerItem?.step(byCount: 1)
                
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
    }
    
    public func goToBegin()
    {
        pause()
        
        Globals.player!.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    public func goToEnd()
    {
        pause()
        
        let endOfMovie = Globals.playerItem.asset.duration
        Globals.player!.seek(to: endOfMovie, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    public func goToMarkIn()
    {
        pause()
        
        Globals.player.seek(to: markIn, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    public func goToMarkOut()
    {
        pause()
        
        Globals.player.seek(to: markOut, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    public func setMarkIn()
    {
        markIn = Globals.player.currentTime()
    }
    
    public func setMarkOut()
    {
        markOut = Globals.player.currentTime()
    }
    
    public func clearMarkIn()
    {
        markIn = CMTime.zero
    }
    
    public func clearMarkOut()
    {
        markOut = Globals.playerItem.asset.duration
    }
    
    public func clearBothMarks()
    {
        clearMarkIn()
        clearMarkOut()
    }
}
