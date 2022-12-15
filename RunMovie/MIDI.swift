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
public var midiSrc:MIDIEndpointRef = MIDIGetSource(0) // should be Arturia BeatStep Pro Arturia BeatStepPro

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
public let knob4: UInt8 = 0x4C
public let knob5: UInt8 = 0x4D          // port B coarse jog
public let knob6: UInt8 = 0x5D          // port B medium jog
public let knob7: UInt8 = 0x49          // port B fine   jog
public let knob8: UInt8 = 0x4B

// bottom row

public let knob9:  UInt8 = 0x72         // both ports coarse jog
public let knob10: UInt8 = 0x12         // both ports medium jog
public let knob11: UInt8 = 0x13         // both ports fine   jog
public let knob12: UInt8 = 0x10
public let knob13: UInt8 = 0x11
public let knob14: UInt8 = 0x5B
public let knob15: UInt8 = 0x4F
public let knob16: UInt8 = 0x48

// for jog operations

public let jogCoarse: UInt8 = 1         // move one percent per jog click
public let jogMedium: UInt8 = 2         // move one second  per jog click
public let jogFine: UInt8 = 3           // move one frame   per jog click

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
        
        dumpStr = ""

        var ignore: Bool = true
        
        for (_, attr) in bytes.enumerated()
        {
            
            j = j + 1
            if ( j == 1 || j == 4 )
            {
                cmd = attr.value as! UInt8
                
                switch ( cmd )
                {
                    case noteOn0:  // 90   begin note on channel 0
                        
                        noteOrKnob = 0
                        
                    case knob0:   // B0   knob changed in command mode on channel 0
                        
                        noteOrKnob = 0

                    case play0:   // FA   start == play
                        
                        noteOrKnob = 0

                    case pause0:   // FC   stop == pause
                        
                        noteOrKnob = 0

                    default:
                        
                        ignore = true
                        // return  // all others are ignored
                }
            }
            else if ( j == 2 || j == 5 )
            {
                noteOrKnob = attr.value as! UInt8
                
                if ( cmd == noteOn0 )       // begin note on channel 0
                {
                    
                    if ( noteOrKnob >= 26 && noteOrKnob <= 51 )     // hex 24 -> 33     pads
                    {
                        ignore = false
                    }
                }
                else if ( cmd == knob0 )  // knob in Command mode on channel 0
                {
                    // check for knobs
                    
                    switch ( noteOrKnob )
                    {
                        case knob1, knob2, knob3, knob5, knob6, knob7, knob9, knob10, knob11:

                            ignore = false

                        default:
                            
                            ignore = true
                    }
                    
                }
                else if ( cmd == play0 || cmd == pause0 )        // play or pause
                {
                    ignore = false
                }
                            
                if ( ignore )
                {
                    dumpStr += String(format:"$%02X ignored", attr.value as! UInt8)
                    print(dumpStr)
                    
                    return
                }
            }
            else if ( j == 3 || j == 6 )
            {
                let temp = attr.value as! UInt8

                value = Int(temp)
            }
            
            dumpStr += String(format:"$%02X ", attr.value as! UInt8)
            
            i -= 1
            if (i <= 0)
            {
                break
            }
        }
        
        print(dumpStr)

        handleMIDIdata(cmd: cmd, noteOrKnob: noteOrKnob, value: value)

        packet = MIDIPacketNext(&packet).pointee
        
    }
    

}

func handleMIDIdata( cmd: UInt8, noteOrKnob: UInt8, value: Int )
{
    let cmdStr = String(format:"$%02X ", cmd)
    let noteOrKnobStr = String(format:"$%02X ", noteOrKnob)
    let valueStr = String(format:"$%02X ", value)
    
    let dumpStr = cmdStr + noteOrKnobStr + valueStr
    
    // print( dumpStr )
    
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
                        player!.play()
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
                        player!.play()
                    }
                    
                case rewindAll:      // rewind both A + B
                    
                    player!.pause()
                    player.seek(to: .zero)
                    
                case playAll:      // play both A + B
                    
                    player!.play()
                    
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
                    
                case knob9:
                
                    jogPlayer( jogScale: jogCoarse , jogValue: value )
                    
                case knob10:
                    
                    jogPlayer( jogScale: jogMedium , jogValue: value )
                    
                case knob11:
                    
                    jogPlayer( jogScale: jogFine , jogValue: value )
                    
                default:
                    
                    return
            }
            
            
        case play0:      // play on MIDI channel zero
            
            player!.play()
            
        case pause0:      // pause on MIDI channel zero
            
            player!.pause()
            
        default:
            return
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
