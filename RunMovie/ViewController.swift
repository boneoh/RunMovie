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

import Network
import Combine

class ViewController: NSViewController {
    @IBOutlet weak var playerView: AVPlayerView!
    
    var listener: UDPListener!
    
    var subscription: AnyCancellable?
    
        // var player: AVPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
            // Do any additional setup after loading the view.
        
        logger.log("*** In ViewController viewDidLoad")
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            if self.myKeyDown(with: $0) {
                return nil
            } else {
                return $0
            }
        }
        
        var c = 0
        for arg in CommandLine.arguments {
            logger.log("argument \(c, privacy: .public) is: \(arg, privacy: .public)")
            c += 1
        }
        
        if CommandLine.argc >= 2
        {
            movieFilepath = CommandLine.arguments[1]
            
            if CommandLine.argc >= 2
            {
                let portReq = CommandLine.arguments[2]
                if ( portReq == "A" )
                {
                    port = portA
                }
                else if ( portReq == "B")
                {
                    port = portB
                }
            }
        }
        else if CommandLine.argc >= 1
        {
            movieFilepath = CommandLine.arguments[0]
        }
        
        logger.log("*** In ViewController viewDidLoad - UDP Port =  \(port.debugDescription, privacy: .public)")
        
        logger.log("*** In ViewController viewDidLoad - movieFilepath =  \(movieFilepath, privacy: .public)")
        
        
        mainScreenName = NSScreen.screens[0].localizedName      // always the main display
        
        c = 0
        for screen in NSScreen.screens {
            logger.log("screen \(c) is: \(screen.localizedName, privacy: .public)")
            c += 1
        }
        
        let url = URL(fileURLWithPath: movieFilepath)
        
            //
        
        let asset =   AVAsset(url: url)
        
        let assetKeys = [
            "playable",
            "hasProtectedContent"
        ]
        
            // Create a new AVPlayerItem with the asset and an
            // array of asset keys to be automatically loaded
        
        logger.log("*** In ViewController viewDidLoad - creating playerItem")
        
        playerItem = AVPlayerItem(asset: asset,
                                  automaticallyLoadedAssetKeys: assetKeys)
        
            // Register as an observer of the player item's status property
        
        /*
         playerItem.addObserver(self,
         forKeyPath: #keyPath(AVPlayerItem.status),
         options: [.old, .new],
         context: &playerItemContext)
         */
        
            // Associate the player item with the player
        
        logger.log("*** In ViewController viewDidLoad - create an AVPlayer bound to the player item")
        
        player =   AVPlayer(playerItem: playerItem)
        
        if player.error != nil {
            let emsg = player.error?.localizedDescription
            logger.log("*** In ViewController viewDidLoad - player.error  \(emsg ?? "?" , privacy: .public)")
        }
        
        logger.log("*** In ViewController viewDidLoad - set playerView.videoGravity")
        
        self.playerView.videoGravity = .resizeAspectFill
        
        logger.log("*** In ViewController viewDidLoad - set playerView.player")
        
        playerView.player = player
        
            // loop video. there is a small delay :(
        
        logger.log("*** In ViewController viewDidLoad - set player observer")
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { notification in
            logger.log("*** In ViewController player observer invoke seek to zero, play")
            player.seek(to: .zero)
            player.play()
        }
        
        logger.log("*** In ViewController viewDidLoad - set player preventsDisplaySleepDuringVideoPlayback")
        
        player.preventsDisplaySleepDuringVideoPlayback = true
        
            //  player.play()
        
        logger.log("*** In ViewController viewDidLoad - creating UDPListener")
        
        listener = UDPListener(on: port)
        
        subscription = listener.$messageReceived.sink(receiveValue: { msgData in
            
            let str = String(decoding: msgData ?? Data(), as: UTF8.self)
            print("*** In ViewController viewDidLoad $messageReceived sink \(str)")
            
            let intKeyCode = Int.init(str)
            _ = self.handleKeyPress(keyCode: intKeyCode ?? 0)
        })
        
        /*
         var cancellable = viewModel.$title.sink(receiveValue: { newTitle in
         print("Title changed to \(newTitle)")
         })
         */
        
        logger.log("*** In ViewController viewDidLoad - get MIDI info")
        
        getMIDINames()
        
        MIDIClientCreate("RunMovie" as CFString, nil, nil, &midiClient)
        
        MIDIInputPortCreate(midiClient, "RunMovie_InPort" as CFString, MyMIDIReadProc, nil, &midiInPort)
        
        MIDIPortConnectSource(midiInPort, midiSrc, &midiSrc)
        
        logger.log("*** In ViewController viewDidLoad - viewDidLoad completed")
    }
    
    
    func handleKeyPress( keyCode: Int ) -> Bool
    {
        switch Int( keyCode) {
                
            case kVK_Escape:          // Toggle Full Screen
                
                logger.log("*** In ViewController handleKeyPress for <Esc>  - setting toggleFullScreen(true)")
                
                NSApplication.shared.mainWindow?.toggleFullScreen(true)
                
                return true
                
                
            case kVK_ANSI_P:          // Play player
                
                logger.log("*** In ViewController handleKeyPress for <Esc>  - invoking player.play()")
                
                player.play()
                
                return true
                
            case kVK_ANSI_Q:          // Quit player
                
                logger.log("*** In ViewController handleKeyPress for <Esc>  - invoking terminate(self)")
                
                NSApplication.shared.terminate(self)
                
                return true
                
            case kVK_ANSI_R:          // Rewind player
                
                logger.log("*** In ViewController handleKeyPress for <Esc>  - invoking player.seek(to: .zero)")
                
                player.seek(to: .zero)
                
                return true
                
            case kVK_ANSI_S, kVK_Space: // Stop player
                
                logger.log("*** In ViewController handleKeyPress for <Esc>  - invoking player.pause()")
                
                player.pause()
                
                return true
                
            case kVK_LeftArrow:       // backward one frame
                
                logger.log("*** In ViewController handleKeyPress for <Esc>  - invoking            playerItem?.step(byCount: -1)")
                
                player.pause()
                playerItem?.step(byCount: -1)
                
                return true
                
            case kVK_RightArrow:      // forward one frame
                
                logger.log("*** In ViewController handleKeyPress for <Esc>  - invoking            playerItem?.step(byCount: 1)")
                
                player.pause()
                playerItem?.step(byCount: 1)
                
                return true
                
            default:
                logger.log("*** In ViewController handleKeyPress - unrecognized key code =  \(keyCode, privacy: .public)")
                
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
    
    override var representedObject: Any? {
        didSet {
                // Update the view, if already loaded.
        }
    }
    
}
