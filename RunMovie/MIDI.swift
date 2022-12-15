//
//  MIDI.swift
//  RunMovie
//
//  Created by peterappleby on 12/14/22.
//

import Foundation
import CoreMIDI

public var midiClient: MIDIClientRef = 0
public var midiInPort:MIDIPortRef = 0
public var midiSrc:MIDIEndpointRef = MIDIGetSource(0) // should be Arturia BeatStep Pro Arturia BeatStepPro

// commands

public let noteOn0: UInt8 = 0x90
public let knob0: UInt8 = 0xB0
public let play0: UInt8 = 0xFA
public let pause0: UInt8 = 0xFC

public let rewindA: UInt8 = 0x2C
public let pauseA: UInt8 = 0x2D
public let playA: UInt8 = 0x2E
public let rewindB: UInt8 = 0x2F
public let pauseB: UInt8 = 0x30
public let playB: UInt8 = 0x31
public let rewindAll: UInt8 = 0x32
public let playAll: UInt8 = 0x33

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
        
        var ignore: Bool = true
        
        for (_, attr) in bytes.enumerated()
        {
            
            j = j + 1
            if ( j == 1 )
            {
                cmd = attr.value as! UInt8
                
                switch ( cmd )
                {
                    case noteOn0:   // 90   begin note
                        
                        note = 0
                        
                    case knob0:   // B0   knob changed in command mode
                        
                        note = 0

                    case play0:   // FA   start == play
                        
                        note = 0

                    case pause0:   // FC   stop == pause
                        
                        note = 0

                    default:
                        ignore = true
                        // return  // all others are ignored
                }
            }
            else if ( j == 2 )
            {
                note = attr.value as! UInt8
                
                if ( cmd == noteOn0 )       // begin note
                {
                    
                    if ( note >= 26 && note <= 51 )     // hex 24 -> 33     pads
                    {
                        ignore = false
                    }
                }
                else if ( cmd == knob0 )  // knob in Command mode
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
                else if ( cmd == play0 || cmd == pause0 )        // play or pause
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

public func handleMIDIdata( cmd: UInt8, note: UInt8, knob: UInt8 )
{
    let cmdStr = String(format:"$%02X ", cmd)
    let noteStr = String(format:"$%02X ", note)
    let knobStr = String(format:"$%02X ", knob)
    
    let dumpStr = cmdStr + " " + noteStr + " " + knobStr
    
    print( dumpStr )
    
    switch ( cmd )
    {
        case noteOn0:      // begin note on MIDI channel zero
            
            switch ( note )
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
            
        case knob0:      // knob on MIDI channel zero
            
            return       // ignore for now
            
        case play0:      // play on MIDI channel zero
            
            player!.play()
            
        case pause0:      // pause on MIDI channel zero
            
            player!.pause()
            
        default:
            return
    }

}
