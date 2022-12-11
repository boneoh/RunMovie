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

class ViewController: NSViewController {
    @IBOutlet weak var playerView: AVPlayerView!
    
    var connection: NWConnection?
    
    var host: NWEndpoint.Host = "127.0.0.1"
    var port: NWEndpoint.Port = 1000
    
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
        }
        else if CommandLine.argc >= 1
        {
            movieFilepath = CommandLine.arguments[0]
        }
        
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
        
        
        logger.log("*** In ViewController viewDidLoad - initialize UDP networking - connect")
        
        connect()

        logger.log("*** In ViewController viewDidLoad - viewDidLoad completed")
    }
    
    
      func send(_ payload: Data) {
          connection!.send(content: payload, completion: .contentProcessed({ sendError in
              if let error = sendError {
                  NSLog("Unable to process and send the data: \(error)")
              } else {
                  NSLog("Data has been sent")
                  self.connection!.receiveMessage { (data, context, isComplete, error) in
                      guard let myData = data else { return }
                      NSLog("Received message: " + String(decoding: myData, as: UTF8.self))
                  }
              }
          }))
      }
      
      func connect() {
          connection = NWConnection(host: host, port: port, using: .udp)
          
          connection!.stateUpdateHandler = { (newState) in
              switch (newState) {
              case .preparing:
                  NSLog("Entered state: preparing")
              
              case .ready:
                      
                  NSLog("Entered state: ready")
                      
                      self.connection!.receiveMessage { data, context, isComplete, error in
                          if let unwrappedError = error {
                              print("Error: NWError received in \(#function) - \(unwrappedError)")
                              return
                          }
                          guard isComplete, let data = data else {
                              print("Error: Received nil Data with context - \(String(describing: context))")
                              return
                          }
                       
                          var myData = data
                          let keyCode = Int( myData.remove(at: 0) )
                          
                          let result = self.handleKeyPress(keyCode: keyCode )
                      }
                      
              case .setup:
                  NSLog("Entered state: setup")
              case .cancelled:
                  NSLog("Entered state: cancelled")
              case .waiting:
                  NSLog("Entered state: waiting")
              case .failed:
                  NSLog("Entered state: failed")
              default:
                  NSLog("Entered an unknown state")
              }
          }
          
          connection!.viabilityUpdateHandler = { (isViable) in
              if (isViable) {
                  NSLog("Connection is viable")
              } else {
                  NSLog("Connection is not viable")
              }
          }
          
          connection!.betterPathUpdateHandler = { (betterPathAvailable) in
              if (betterPathAvailable) {
                  NSLog("A better path is availble")
              } else {
                  NSLog("No better path is available")
              }
          }
          
          connection!.start(queue: .global())
          
          
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
        
/*
          switch Int( event.keyCode) {
          
          case kVK_Escape:          // Toggle Full Screen
            
              logger.log("*** In ViewController myKeyDown for <Esc>  - setting toggleFullScreen(true)")
              
              NSApplication.shared.mainWindow?.toggleFullScreen(true)
                        
             return true
              
          /*
           case kVK_ANSI_H:             // Home = main display
                         
              logger.log("*** In ViewController myKeyDown for 'H'")
              
              processingHomeCommand = true
              
              if  isWindowFullScreen == true
              {
                  logger.log("*** In ViewController myKeyDown for 'H' - isWindowFullScreen == true")
                  logger.log("*** In ViewController myKeyDown for 'H' - setting toggleFullScreen(true)")
                  
                  NSApplication.shared.mainWindow?.toggleFullScreen(true)
              }
              
              let dx = 1920.0 / 2.0
              let dy = 1080.0 / 2.0
              
              let screens = NSScreen.screens
              var pos = NSPoint()
              pos.x = screens[0].visibleFrame.midX - dx
              pos.y = screens[0].visibleFrame.midY - dy
              
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                  NSApplication.shared.mainWindow?.setFrameOrigin(pos)
                  NSApplication.shared.mainWindow?.toggleFullScreen(true)
              }
              
              processingHomeCommand = false
              
              return true;
        */

          case kVK_ANSI_P:          // Play player
              
             player.play()
              
             return true
              
          case kVK_ANSI_Q:          // Quit player
              
             NSApplication.shared.terminate(self)
              
             return true
              
          case kVK_ANSI_R:          // Rewind player
             
             player.seek(to: .zero)
              
             return true
              
          case kVK_ANSI_S, kVK_Space: // Stop player
 
             player.pause()
              
             return true
              
          case kVK_LeftArrow:       // backward one frame
              
             player.pause()
             playerItem?.step(byCount: -1)
              
             return true
              
          case kVK_RightArrow:      // forward one frame
              
             player.pause()
             playerItem?.step(byCount: 1)
              
             return true

          default:
             return false
          }
*/
        
       }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}
