//
//  MIDI.swift
//  RunMovie
//
//  Created by peterappleby on 12/14/22.
//

import Foundation
import CoreMIDI

import AVKit
import AVFoundation

public var midiClient: MIDIClientRef = 0
public var midiInPort:MIDIPortRef = 0
public var midiSrc:MIDIEndpointRef = MIDIGetSource(0) // should be "Arturia BeatStepPro"

// All of this assumes my BeatStep Pro

// commands

public let noteOn0: UInt8 = 0x90        // for pads,  used in control mode or drum tracks
public let knob0: UInt8 = 0xB0          // for knobs, used in control mode

// these two are from the transport control

public let play0: UInt8 = 0xFA          // play both ports
public let pause0: UInt8 = 0xFC         // stop and rewind both ports

// pads                                 // top row of drum pads are not being used, not CV capable in my eurorack
                                        // so I use them for video control
public let rewindA: UInt8 = 0x2C
public let pauseA: UInt8 = 0x2D
public let playA: UInt8 = 0x2E
public let rewindB: UInt8 = 0x2F
public let pauseB: UInt8 = 0x30
public let playB: UInt8 = 0x31
public let rewindAll: UInt8 = 0x32
public let playAll: UInt8 = 0x33

// knobs

// top row

public let knob1: UInt8 = 0x0A          // port A coarse jog
public let knob2: UInt8 = 0x4A          // port A medium jog
public let knob3: UInt8 = 0x47          // port A fine   jog
public let knob4: UInt8 = 0x4C          // port A speed
public let knob5: UInt8 = 0x4D          // port B coarse jog
public let knob6: UInt8 = 0x5D          // port B medium jog
public let knob7: UInt8 = 0x49          // port B fine   jog
public let knob8: UInt8 = 0x4B          // port B speed

// bottom row

public let knob9:  UInt8 = 0x72         // both ports coarse jog
public let knob10: UInt8 = 0x12         // both ports medium jog
public let knob11: UInt8 = 0x13         // both ports fine   jog
public let knob12: UInt8 = 0x10         // both ports speed
public let knob13: UInt8 = 0x11
public let knob14: UInt8 = 0x5B
public let knob15: UInt8 = 0x4F
public let knob16: UInt8 = 0x48

// for jog operations

public let jogCoarse: UInt8 = 1         // move one percent per jog click
public let jogMedium: UInt8 = 2         // move one second  per jog click
public let jogFine: UInt8 = 3           // move one frame   per jog click

// remember the playback rate that may have been set by the user

public var playbackRate: Float = 1.0    // knobs can control the playback rate

public func getMIDINames()
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

public func getDisplayName(_ obj: MIDIObjectRef) -> String
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

public func getDestinationNames() -> [String]
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

public func getSourceNames() -> [String]
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

public func MyMIDIReadProc(pktList: UnsafePointer<MIDIPacketList>,
                    readProcRefCon: UnsafeMutableRawPointer?, srcConnRefCon: UnsafeMutableRawPointer?) -> Void
{
    let packetList:MIDIPacketList = pktList.pointee
    
    var packet:MIDIPacket = packetList.packet
    for _ in 1...packetList.numPackets
    {
        let bytes = Mirror(reflecting: packet.data).children
        
            // bytes mirror contains all the zero values in the ridiulous packet data tuple
            // so use the packet length to iterate.

        var i = packet.length
        var j = 0
        var dumpStr = ""
        
        // allow debugging of MIDI commands
        
        for (_, attr) in bytes.enumerated()
        {
            
            j = j + 1
            
            let x = attr.value as! UInt8
            dumpStr += String(format:"$%02X ", x)
            
            if (j >= 10 )
            {
                break
            }
        }
        
        j = 0
        
        // print(dumpStr)

        var cmd: UInt8 = 0
        var noteOrKnob: UInt8 = 0
        var value: Int = 0
        
        var cmdStr: String = ""
        var noteOrKnobStr: String = ""
        var valueStr: String = ""

        var ignore: Bool = false
        
        for (_, attr) in bytes.enumerated()
        {
            
            j = j + 1
            if ( j == 1 || j == 4 )
            {
                cmd = attr.value as! UInt8
                
                switch ( cmd )
                {
                    case noteOn0:  // 90   begin note on channel 0
                        
                        cmdStr = "Note On "
                        
                    case knob0:   // B0   knob changed in command mode on channel 0
                        
                        cmdStr = "Knob "

                    case play0:   // FA   start == play
                        
                        cmdStr = "Transport Play "

                    case pause0:   // FC   stop == pause
                        
                        cmdStr = "Transport Pause "

                    default:
                        cmdStr = "Unknown command " + String(format:"$%02X ", cmd) + " " + dumpStr + " "
                        ignore = true

                }
            }
            else if ( j == 2 || j == 5 )
            {
                noteOrKnob = attr.value as! UInt8
                
                if ( cmd == noteOn0 )       // begin note on channel 0
                {
                    
                    switch ( noteOrKnob )
                    {
                        case rewindA:
                            noteOrKnobStr = "Rewind A "
                        
                        case pauseA:
                            noteOrKnobStr = "Pause A "
                        
                        case playA:
                            noteOrKnobStr = "Play A "

                        case rewindB:
                            noteOrKnobStr = "Rewind A "
                        
                        case pauseB:
                            noteOrKnobStr = "Pause B "
                        
                        case playB:
                            noteOrKnobStr = "Play B "
                            
                        case rewindAll:
                            noteOrKnobStr = "Rewind All "
                        
                        case playAll:
                            noteOrKnobStr = "Play All "

                        default:
                            noteOrKnobStr = "unknown Pad command " + String(format:"$%02X ", noteOrKnob) + " "  + dumpStr + " "
                            ignore = true
                    }

                }
                else if ( cmd == knob0 )  // knob in Command mode on channel 0
                {
                    // check for knobs
                    
                    switch ( noteOrKnob )
                    {
                        // case knob1, knob2, knob3, knob5, knob6, knob7, knob9, knob10, knob11:

                        case knob1:
                            noteOrKnobStr = "Knob 1 - Jog A Coarse "
      
                        case knob2:
                            noteOrKnobStr = "Knob 2 - Jog A Medium "

                        case knob3:
                            noteOrKnobStr = "Knob 3 - Jog A Fine "

                        case knob4:
                            noteOrKnobStr = "Knob 4 - Play A Speed "

                        case knob5:
                            noteOrKnobStr = "Knob 5 - Jog B Coarse "

                        case knob6:
                            noteOrKnobStr = "Knob 6 - Jog B Medium "

                        case knob7:
                            noteOrKnobStr = "Knob 7 - Jog B Fine "

                        case knob8:
                            noteOrKnobStr = "Knob 8 - Play B Speed "

                        case knob9:
                            noteOrKnobStr = "Knob 9 - Jog All Coarse "

                        case knob10:
                            noteOrKnobStr = "Knob 10 - Jog All Medium "

                        case knob11:
                            noteOrKnobStr = "Knob 11 - Jog All Fine "

                        case knob12:
                            noteOrKnobStr = "Knob 12 - Play All Speed "

                        default:
                            noteOrKnobStr = "unknown Knob command " + String(format:"$%02X ", noteOrKnob) + " " + dumpStr + " "
                            ignore = true
                    }
                    
                }
                else if ( cmd == play0 )        // play
                {
                    noteOrKnobStr = "Transport Play "
                }
                else if ( cmd == pause0 )       // pause
                {
                    noteOrKnobStr = "Transport Pause "
                    ignore = false
                }
                else
                {
                    noteOrKnobStr = "Unknown command " + String(format:"$%02X ", cmd) + " " + dumpStr + " "
                    ignore = true
                }
                
            }
            else if ( j == 3 || j == 6 )
            {
                let temp = attr.value as! UInt8

                value = Int(temp)
                valueStr = String(value)
            }
            
            i -= 1
            if (i <= 0)
            {
                break
            }
        }
        
        dumpStr = cmdStr + noteOrKnobStr + valueStr
        
        print(dumpStr)

        if ( ignore == false )
        {
            handleMIDIdata(cmd: cmd, noteOrKnob: noteOrKnob, value: value)
        }
        
        packet = MIDIPacketNext(&packet).pointee
        
    }

}

func handleMIDIdata( cmd: UInt8, noteOrKnob: UInt8, value: Int )
{
    /*
    let cmdStr = String(format:"$%02X ", cmd)
    let noteOrKnobStr = String(format:"$%02X ", noteOrKnob)
    let valueStr = String(format:"$%02X ", value)
    
    // let dumpStr = cmdStr + noteOrKnobStr + valueStr
    
    print( dumpStr )
    */
    
    switch ( cmd )
    {
        case noteOn0:      // begin note on MIDI channel zero
            
            switch ( noteOrKnob )
            {
                case rewindA:      // rewind port A
                    
                    if ( port == portA )
                    {
                        player!.pause()
                        player!.seek(to: .zero)
                    }
                    
                case pauseA:      // stop port A
                    
                    if ( port == portA )
                    {
                        player!.pause()
                    }
                    
                case playA:      // play port A
                    
                    if ( port == portA )
                    {
                        player!.rate = playbackRate
                        // player!.play()
                    }
                    
                case rewindB:      // rewind port B
                    
                    if ( port == portB )
                    {
                        player!.pause()
                        player!.seek(to: .zero)
                    }
                    
                case pauseB:      // stop port B
                    
                    if ( port == portB )
                    {
                        player!.pause()
                    }
                    
                case playB:      // play port B
                    
                    if ( port == portB )
                    {
                        player!.rate = playbackRate
                        // player!.play()
                    }
                    
                case rewindAll:      // rewind both A + B
                    
                    player!.pause()
                    player.seek(to: .zero)
                    
                case playAll:      // play both A + B
                    
                    player!.rate = playbackRate
                    // player!.play()
                    
                default:
                    
                    return
            }
            
        case knob0:      // knob in Control mode on MIDI channel zero
            
            // print( dumpStr )
            
            switch ( noteOrKnob )
            {
                case knob1:
                
                    if ( port == portA )
                    {
                        jogPlayer( jogScale: jogCoarse , jogValue: value )
                    }
                    
                case knob2:
                    
                    if ( port == portA )
                    {
                        jogPlayer( jogScale: jogMedium , jogValue: value )
                    }
                    
                case knob3:
                    
                    if ( port == portA )
                    {
                        jogPlayer( jogScale: jogFine , jogValue: value )
                    }
                    
                case knob4:
                    
                    if ( port == portA )
                    {
                        playerSpeed(speedValue: value ) // set playback speed and direction
                    }

                case knob5:
                
                    if ( port == portB )
                    {
                        jogPlayer( jogScale: jogCoarse , jogValue: value )
                    }
                    
                case knob6:
                    
                    if ( port == portB )
                    {
                        jogPlayer( jogScale: jogMedium , jogValue: value )
                    }
                    
                case knob7:
                    
                    if ( port == portB )
                    {
                        jogPlayer( jogScale: jogFine , jogValue: value )
                    }
                    
                case knob8:
                    
                    if ( port == portB )
                    {
                        playerSpeed(speedValue: value ) // set playback speed and direction
                    }
                    
                case knob9:
                
                    jogPlayer( jogScale: jogCoarse , jogValue: value )
                    
                case knob10:
                    
                    jogPlayer( jogScale: jogMedium , jogValue: value )
                    
                case knob11:
                    
                    jogPlayer( jogScale: jogFine , jogValue: value )
                    
                case knob12:
                    
                    playerSpeed(speedValue: value ) // set playback speed and direction

                default:
                    
                    return
            }
            
            
        case play0:      // play on MIDI channel zero
            
            player!.rate = playbackRate
            player!.play()
            
        case pause0:      // pause on MIDI channel zero
            
            player!.pause()
            
        default:
            return
    }
    
    func playerSpeed( speedValue: Int )
    {
        //  Would be nice to have a similar function receive a Note value
        //  and explicitly set the playback speed. Currently the knob may
        //  need to be turned many times to get to an approximate speed.
        
        var value: Float = 0.0
        
        if ( speedValue >= 127 )
        {
            value = player.rate - 0.1
        }
        else if ( speedValue == 1 )
        {
            value = player.rate + 0.1
        }
        else
        {
            return  // ignore value == 0
        }
        
        if ( value <= 10.0 && value >= -10.0 )
        {
            player.rate = value
            
            let speedStr = String(format:"$%.2f ", player.rate)
            print(speedStr)
            
            playbackRate = player.rate
        }
    }
    
    func jogPlayer( jogScale: UInt8, jogValue: Int )
    {
    
        if ( player == nil || playerItem == nil || jogValue == 0 )
        {
            return
        }
        
        var value = jogValue
        
        if ( value >= 127 )
        {
            value = -1
        }
    
        let tracks = playerItem.asset.tracks(withMediaType: .video)
        let fps = tracks.first?.nominalFrameRate
        let duration = playerItem.asset.duration

        let videoFPS = Double(fps!)
        let totalFrames = Double(videoFPS) * duration.seconds
        
        var unitSize: Double = 1
        
        switch ( jogScale)
        {
            case jogCoarse:
                
                unitSize = totalFrames / 100.0  // one percent of total frames
                
            case jogMedium:
                
                unitSize = videoFPS     // one second
                
            case jogFine:
                
                unitSize = 1.0          // one frame
                
            default:
                
                unitSize = 1.0
        }
               
        if ( unitSize < 1.0 )
        {
            unitSize = 1.0
        }
        else if ( unitSize > totalFrames )
        {
            unitSize = totalFrames - 1
        }
        
        let span = Double(value) * unitSize / videoFPS
        
        player!.pause()

        let currentTime = player.currentTime()
        let newTime = currentTime.seconds.advanced(by: span)
        
        let seekTime = CMTimeMakeWithSeconds(newTime, preferredTimescale: 1000 )
                
        player.seek(to: seekTime)
        
    }

}
