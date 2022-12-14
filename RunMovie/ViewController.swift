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
import CoreMIDI

import Network
import Combine

class ViewController: NSViewController {
    @IBOutlet weak var playerView: AVPlayerView!
    
    var listener: UDPListener!

    
    var subscription: AnyCancellable?
    
    var midiClient: MIDIClientRef = 0
    var midiInPort:MIDIPortRef = 0
    var midiSrc:MIDIEndpointRef = MIDIGetSource(0) // should be Arturia BeatStep Pro Arturia BeatStepPro
    
    
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
            self.handleKeyPress(keyCode: intKeyCode ?? 0)
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
    
    func getMIDINames()
    {
        let destNames = getDestinationNames();
        
        print("Number of MIDI Destinations: \(destNames.count)");
        for destName in destNames
        {
            print("  Destination: \(destName)");
        }
        
        let sourceNames = getSourceNames();
        
        print("\nNumber of MIDI Sources: \(sourceNames.count)");
        for sourceName in sourceNames
        {
            print("  Source: \(sourceName)");
        }
    }
    
    func getDisplayName(_ obj: MIDIObjectRef) -> String
    {
        var param: Unmanaged<CFString>?
        var name: String = "Error"
        
        let err: OSStatus = MIDIObjectGetStringProperty(obj, kMIDIPropertyDisplayName, &param)
        if err == OSStatus(noErr)
        {
            name =  param!.takeRetainedValue() as String
        }
        
        return name
    }
    
    func getDestinationNames() -> [String]
    {
        var names:[String] = [];
        
        let count: Int = MIDIGetNumberOfDestinations();
        for i in 0..<count {
            let endpoint:MIDIEndpointRef = MIDIGetDestination(i);
            
            if (endpoint != 0)
            {
                names.append(getDisplayName(endpoint));
            }
        }
        return names;
    }
    
    func getSourceNames() -> [String]
    {
        var names:[String] = [];
        
        let count: Int = MIDIGetNumberOfSources();
        for i in 0..<count {
            let endpoint:MIDIEndpointRef = MIDIGetSource(i);
            if (endpoint != 0)
            {
                names.append(getDisplayName(endpoint));
            }
        }
        return names;
    }
    
}

    func MyMIDIReadProc(pktList: UnsafePointer<MIDIPacketList>,
                        readProcRefCon: UnsafeMutableRawPointer?, srcConnRefCon: UnsafeMutableRawPointer?) -> Void
    {
        let packetList:MIDIPacketList = pktList.pointee
            // $$$ let srcRef:MIDIEndpointRef = srcConnRefCon!.load(as: MIDIEndpointRef.self)
        
            // $$$ print("MIDI Received From Source: \(getDisplayName(srcRef))")
        
        var packet:MIDIPacket = packetList.packet
        for _ in 1...packetList.numPackets
        {
            let bytes = Mirror(reflecting: packet.data).children
            var dumpStr = ""
            
                // bytes mirror contains all the zero values in the ridiulous packet data tuple
                // so use the packet length to iterate.
            var i = packet.length
            var j = 0
            
            var cmd: UInt8 = 0
            var note: UInt8 = 0
            var knob: UInt8 = 0
            
            for (_, attr) in bytes.enumerated()
            {
                j = j + 1
                if ( j == 1 )
                {
                    cmd = attr.value as! UInt8
                    
                    switch ( cmd )
                    {
                        case 144:   // 90   begin note
                            
                            note = 0
                            
                        case 176:   // B0   knob changed in command mode
                            
                            note = 0

                        case 250:   // FA   start == play
                            
                            note = 0

                        case 252:   // FC   stop == pause
                            
                            note = 0

                        default:
                            return  // all others are ignored 
                    }
                }
                else if ( j == 2 )
                {
                    note = attr.value as! UInt8
                    
                    var ignore: Bool = true
                    
                    if ( cmd == 144 )       // begin note
                    {
                        
                        if ( note >= 26 && note <= 51 )     // hex 24 -> 33     pads
                        {
                            ignore = false
                        }
                    }
                    else if ( cmd == 176 )  // knob in Command mode
                    {
                        // check for knobs
                        
                        switch ( note )
                        {
                            case 0x0A, 0x4A, 0x47, 0x4C, 0x4D, 0x5D, 0x49, 0x4B:    // top row of knobs in Control mode
                                
                                ignore = false
                            
                            case 0x72, 0x12, 0x13, 0x10, 0x11, 0x5B, 0x4F, 0x48:    // bottom row of knobs in Control mode
                                
                                ignore = false
                                
                            default:

                                ignore = true
                        }
                    }
                    else if ( cmd == 250 || cmd == 252 )        // start or stop
                    {
                        ignore = false
                    }
                                
                    if ( ignore )
                    {
                        return
                    }
                }
                else if ( j == 3 )
                {
                    knob = attr.value as! UInt8
                }
                
                dumpStr += String(format:"$%02X ", attr.value as! UInt8)
                
                i -= 1
                if (i <= 0)
                {
                    break
                }
            }
            
            // print(dumpStr)

            handleMIDIdata(cmd: cmd, note: note, knob: knob)

            packet = MIDIPacketNext(&packet).pointee
            
        }
        

    }

