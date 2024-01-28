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

// MIDI Channels are 1 - 16, but commands are suffixed 0x_0 to 0x_F

// We are looking for Port A, Port B, Port C and common subset.

public let channel01: UInt8 = 0x00
public let channel02: UInt8 = 0x01
public let channel03: UInt8 = 0x02
public let channel04: UInt8 = 0x03
public let channel05: UInt8 = 0x04
public let channel06: UInt8 = 0x05
public let channel07: UInt8 = 0x06
public let channel08: UInt8 = 0x07
public let channel09: UInt8 = 0x08
public let channel10: UInt8 = 0x09
public let channel11: UInt8 = 0x0A  // RunMovie on iMac, port A
public let channel12: UInt8 = 0x0B  // RunMovie on iMac, port B
public let channel13: UInt8 = 0x0C  // RunMovie on iMac, port C
public let channel14: UInt8 = 0x0D  // CUDA programs on Jetson Nano
public let channel15: UInt8 = 0x0E  // Blackmagic Design HyperDeck HD Mini
public let channel16: UInt8 = 0x0F  // common subset of commands, used for all channels

public let commandMask: UInt8 = 0xF0
public let channelMask: UInt8 = 0x0F

// channels to be monitored

public var channelListen:       UInt8 = 0       // for RunMovie will be either channelA, channelB, channelC

public let channelA:            UInt8 = channel11
public let channelB:            UInt8 = channel12
public let channelC:            UInt8 = channel13
public var channelCommon:       UInt8 = channel16

// commands

public let noteOn:          UInt8 = 0x90        // for pads used in control mode
public let knobOrButton:    UInt8 = 0xB0        // for knobs and buttons used in control mode

// these two are from the transport control

public let transportPlay: UInt8 = 0xFA
public let transportStop: UInt8 = 0xFC

// pads
     
// top row

public let pad09: UInt8 = 0x2C
public let pad10: UInt8 = 0x2D
public let pad11: UInt8 = 0x2E
public let pad12: UInt8 = 0x2F
public let pad13: UInt8 = 0x30
public let pad14: UInt8 = 0x31
public let pad15: UInt8 = 0x32
public let pad16: UInt8 = 0x33

// bottom row

public let pad01: UInt8 = 0x24
public let pad02: UInt8 = 0x25
public let pad03: UInt8 = 0x26
public let pad04: UInt8 = 0x27
public let pad05: UInt8 = 0x28
public let pad06: UInt8 = 0x29
public let pad07: UInt8 = 0x2A
public let pad08: UInt8 = 0x2B

// knobs

// top row

public let knob01: UInt8 = 0x0A //  Pan
public let knob02: UInt8 = 0x4A //  Brightness
public let knob03: UInt8 = 0x47 //  Timbre/Harmonic Intens.
public let knob04: UInt8 = 0x4C //  Vibrato Rate
public let knob05: UInt8 = 0x4D //  Vibrato Depth
public let knob06: UInt8 = 0x5D //  Chorus Send Level
public let knob07: UInt8 = 0x49 //  Attack Time
public let knob08: UInt8 = 0x4B //  Decay Time

// bottom row

public let knob09: UInt8 = 0x72 //  Undefined
public let knob10: UInt8 = 0x12 //  General Purpose 3
public let knob11: UInt8 = 0x13 //  General Purpose 4
public let knob12: UInt8 = 0x10 //  General Purpose 1
public let knob13: UInt8 = 0x11 //  General Purpose 2
public let knob14: UInt8 = 0x5B //  Reverb Send Level
public let knob15: UInt8 = 0x4F //  Sound Controller 10
public let knob16: UInt8 = 0x48 //  Release Time

// buttons

// top row

public let button01: UInt8 = 0x14 //  Undefined
public let button02: UInt8 = 0x15 //  Undefined
public let button03: UInt8 = 0x16 //  Undefined
public let button04: UInt8 = 0x17 //  Undefined
public let button05: UInt8 = 0x18 //  Undefined
public let button06: UInt8 = 0x19 //  Undefined
public let button07: UInt8 = 0x1A //  Undefined
public let button08: UInt8 = 0x1B //  Undefined

// bottom row

public let button09: UInt8 = 0x1C //  Undefined
public let button10: UInt8 = 0x1D //  Undefined
public let button11: UInt8 = 0x1E //  Undefined
public let button12: UInt8 = 0x1F //  Undefined
public let button13: UInt8 = 0x34 //  Undefined
public let button14: UInt8 = 0x35 //  Undefined
public let button15: UInt8 = 0x36 //  Undefined
public let button16: UInt8 = 0x37 //  Undefined


// for jog operations

public let jogCoarse: UInt8 = 1         // move one percent per jog click
public let jogMedium: UInt8 = 2         // move one second  per jog click
public let jogFine: UInt8 = 3           // move one frame   per jog click

// remember the playback rate that may have been set by the user

public var playbackRate: Float = 1.0    // knobs can control the playback rate

//  remember the In and Out times set by the user with the Mark commands

public var markIn:  CMTime = CMTime.zero
public var markOut: CMTime = CMTime.zero

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

        var channel: UInt8 = 0
        var cmd: UInt8 = 0
        var padOrKnob: UInt8 = 0
        var value: Int = 0
        
        var channelStr: String = ""
        var cmdStr: String = ""
        var padOrKnobStr: String = ""
        var valueStr: String = ""

        var isKnob: Bool = false
        var isPad: Bool = false
        var isButton: Bool = false
        
        for (_, attr) in bytes.enumerated()
        {
            
            j = j + 1
            if ( j == 1 || j == 4 )
            {
                let rawCmd = attr.value as! UInt8
                
                cmd = rawCmd & commandMask
                channel = rawCmd & channelMask
                
                let channel1 = channel + 1
                
                channelStr = "Channel " + String(format:"%02X ", channel) + " " + String(format:"%i ", channel1) + " "
                
                switch ( channel )
                {
                    case channelListen, channelCommon:
                        
                        switch ( cmd )
                        {
                            case noteOn:
                                
                                cmdStr = "Note On "
                                
                            case knobOrButton:
                                
                                cmdStr = "Knob "
                                
                            case transportPlay:
                                
                                cmdStr = "Transport Play "
                                
                            case transportStop:
                                
                                cmdStr = "Transport Pause "
                                
                            default:
                                
                                cmdStr = channelStr + "Unknown command " + String(format:"$%02X ", cmd) + " " + dumpStr + " "
                                print( cmdStr)
                                
                                return
                                
                        }
                        
                        break
                        
                    default:
                        return
 
                }
            }
            else if ( j == 2 || j == 5 )
            {
                padOrKnob = attr.value as! UInt8
                
                if ( cmd == noteOn )       // begin note
                {
                    
                    switch ( padOrKnob )
                    {
                        case pad01:
                            padOrKnobStr = "pad01 "
                            isPad = true
                        
                        case pad02:
                            padOrKnobStr = "pad02 "
                            isPad = true

                        case pad03:
                            padOrKnobStr = "pad03 "
                            isPad = true

                        case pad04:
                            padOrKnobStr = "pad04 "
                            isPad = true

                        case pad05:
                            padOrKnobStr = "pad05 "
                            isPad = true

                        case pad06:
                            padOrKnobStr = "pad06 "
                            isPad = true

                        case pad07:
                            padOrKnobStr = "pad07 "
                            isPad = true

                        case pad08:
                            padOrKnobStr = "pad08 "
                            isPad = true

                        case pad09:
                            padOrKnobStr = "pad09 "
                            isPad = true

                        case pad10:
                            padOrKnobStr = "pad10 "
                            isPad = true

                        case pad11:
                            padOrKnobStr = "pad11 "
                            isPad = true

                        case pad12:
                            padOrKnobStr = "pad12 "
                            isPad = true

                        case pad13:
                            padOrKnobStr = "pad13 "
                            isPad = true

                        case pad14:
                            padOrKnobStr = "pad14 "
                            isPad = true

                        case pad15:
                            padOrKnobStr = "pad15 "
                            isPad = true

                        case pad16:
                            padOrKnobStr = "pad16 "
                            isPad = true

                        default:
                            
                            padOrKnobStr = cmdStr + "unknown Pad command " + String(format:"$%02X ", padOrKnob) + " "  + dumpStr + " "
                            print(padOrKnobStr)
                            
                            return
                    }
                     
                }
                else if ( cmd == knobOrButton )  // knob or button in Command mode
                {
                    // check for knobs
                    
                    switch ( padOrKnob )
                    {

                        case knob01:
                            padOrKnobStr = "knob01 "
                            isKnob = true

                        case knob02:
                            padOrKnobStr = "knob02 "
                            isKnob = true

                        case knob03:
                            padOrKnobStr = "knob03 "
                            isKnob = true

                        case knob04:
                            padOrKnobStr = "knob04 "
                            isKnob = true

                        case knob05:
                            padOrKnobStr = "knob05 "
                            isKnob = true

                        case knob06:
                            padOrKnobStr = "knob06 "
                            isKnob = true

                        case knob07:
                            padOrKnobStr = "knob07 "
                            isKnob = true

                        case knob08:
                            padOrKnobStr = "knob08 "
                            isKnob = true

                        case knob09:
                            padOrKnobStr = "knob09 "
                            isKnob = true

                        case knob10:
                            padOrKnobStr = "knob10 "
                            isKnob = true

                        case knob11:
                            padOrKnobStr = "knob11 "
                            isKnob = true

                        case knob12:
                            padOrKnobStr = "knob12 "
                            isKnob = true

                        case knob13:
                            padOrKnobStr = "knob13 "
                            isKnob = true

                        case knob14:
                            padOrKnobStr = "knob14 "
                            isKnob = true

                        case knob15:
                            padOrKnobStr = "knob15 "
                            isKnob = true

                        case knob16:
                            padOrKnobStr = "knob16 "
                            isKnob = true

                        case button01:
                            padOrKnobStr = "button01 "
                            isButton = true

                        case button02:
                            padOrKnobStr = "button02 "
                            isButton = true

                        case button03:
                            padOrKnobStr = "button03 "
                            isButton = true

                        case button04:
                            padOrKnobStr = "button04 "
                            isButton = true

                        case button05:
                            padOrKnobStr = "button05 "
                            isButton = true

                        case button06:
                            padOrKnobStr = "button06 "
                            isButton = true

                        case button07:
                            padOrKnobStr = "button07 "
                            isButton = true

                        case button08:
                            padOrKnobStr = "button08 "
                            isButton = true

                        case button09:
                            padOrKnobStr = "button09 "
                            isButton = true

                        case button10:
                            padOrKnobStr = "button10 "
                            isButton = true

                        case button11:
                            padOrKnobStr = "button11 "
                            isButton = true

                        case button12:
                            padOrKnobStr = "button12 "
                            isButton = true

                        case button13:
                            padOrKnobStr = "button13 "
                            isButton = true

                        case button14:
                            padOrKnobStr = "button14 "
                            isButton = true

                        case button15:
                            padOrKnobStr = "button15 "
                            isButton = true

                        case button16:
                            padOrKnobStr = "button16 "
                            isButton = true

                        default:
                            
                            padOrKnobStr = cmdStr + "unknown Knob or Button command " + String(format:"$%02X ", padOrKnob) + " " + dumpStr + " "
                            
                            print(padOrKnobStr)
                            
                            return
                    }
                    
                    if ( isPad )
                    {
                        cmdStr += "Pad "
                    }
                    else if ( isKnob )
                    {
                        cmdStr += "Knob "
                    }
                    else if ( isButton )
                    {
                        cmdStr += "Button "
                    }
                    
                }
                else if ( cmd == transportPlay )
                {
                    padOrKnobStr = cmdStr + "Transport Play "
                }
                else if ( cmd == transportStop )
                {
                    padOrKnobStr = cmdStr + "Transport Pause "
                }
                else
                {
                    padOrKnobStr = cmdStr + "Unknown command " + String(format:"$%02X ", cmd) + " " + dumpStr + " "
                    
                    print(padOrKnobStr)
                    
                    return
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
        
        dumpStr = cmdStr + padOrKnobStr + valueStr
        
        print(dumpStr)

        handleMIDIdata(cmd: cmd, noteOrKnob: padOrKnob, value: value)
        
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
        case noteOn:      // begin note
            
            switch ( noteOrKnob )
            {
                    
                case pad01:
                    
                    break

                case pad02:      // go to start
                    
                    Globals.viewController?.goToBegin()
                    
                case pad03:      // pause

                    Globals.viewController?.pause()
                    
                case pad04:      // play
                    
                    Globals.viewController?.play()
                    
                case pad05:      // play In to Out
                    
                    Globals.viewController?.playInToOut()

                    break
                    
                case pad06:       // go to end
                    
                    Globals.viewController?.goToEnd()

                case pad07:
                    
                    Globals.viewController?.goToMarkIn()
                    
                    break

                case pad08:
                    
                    Globals.viewController?.goToMarkOut()
                    
                    break

                case pad09:
                    
                    Globals.viewController?.setMarkIn()
                    
                    break

                case pad10:
                    
                    Globals.viewController?.setMarkOut()
                    
                    break

                case pad11:
                    
                    Globals.viewController?.clearMarkIn()
                    
                    break

                case pad12:
                    
                    Globals.viewController?.clearMarkOut()
                    
                    break

                case pad13:
                    
                    Globals.viewController?.clearBothMarks()
                    
                    break

                case pad14:
                    
                    Globals.player.isMuted = true       // pma 1/23/2024
                    
                    break

                case pad15:
                    
                    Globals.player.isMuted = false      // pma 1/23/2024
                    
                    break

                case pad16:
                    
                    Globals.viewController?.exportScreenShot()
                    
                    break
                   
                default:
                    
                    return
            }
            
        case knobOrButton:
            
            // print( dumpStr )
            
            switch ( noteOrKnob )
            {
                case knob01:

                    jogPlayer( jogScale: jogCoarse , jogValue: value )
                    
                case knob02:
                    
                    jogPlayer( jogScale: jogMedium , jogValue: value )
                    
                case knob03:
                    
                    jogPlayer( jogScale: jogFine , jogValue: value )
                    
                case knob04:
                    
                    playerSpeed(speedValue: value ) // set playback speed and direction

                case knob05:
                    
                    break

                case knob06:
                    
                    break

                case knob07:
                    
                    break

                case knob08:
                    
                    break

                case knob09:
                    
                    break

                case knob10:
                    
                    break

                case knob11:
                    
                    break

                case knob12:
                    
                    break

                case knob13:
                    
                    break

                case knob14:
                    
                    break

                case knob15:
                    
                    break

                case knob16:
                    
                    break
                    
                case button01:
                    
                    break
                    
                case button02:      // rewind aka go to start
                    
                    Globals.viewController?.goToBegin()
                    
                case button03:      // pause

                    Globals.viewController?.pause()
                    
                case button04:      // play
                    
                    Globals.viewController?.play()
                    
                case button05:      // play In to Out
                    
                    Globals.viewController?.playInToOut()

                case button06:       // go to end
                    
                    Globals.viewController?.goToEnd()
                     
                case button07:
                    
                    Globals.viewController?.goToMarkIn()
                    
                    break

                case button08:
                    
                    Globals.viewController?.goToMarkOut()
                    
                    break
                    
                case button09:
                    
                    Globals.viewController?.setMarkIn()
                    
                    break

                case button10:
                    
                    Globals.viewController?.setMarkOut()
                    
                    break

                case button11:
                    
                    Globals.viewController?.clearMarkIn()
                    
                    break

                case button12:
                    
                    Globals.viewController?.clearMarkOut()
 
                    break

                case button13:
                    
                    Globals.viewController?.clearBothMarks()
                    
                    break

                case button14:
                    
                    // record, should be handled by MIDI2UDP program
                    
                    break

                case button15:
                    
                    // stop recording, should be handled by MIDI2UDP program
                    
                    break

                case button16:
                    
                    Globals.viewController?.exportScreenShot()
                    
                    break

                default:
                    
                    return
            }
                        
        case transportPlay:
            
            Globals.viewController?.play()
            
        case transportStop:
            
            Globals.viewController?.pause()
            
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
            value = Globals.player.rate - 0.1
        }
        else if ( speedValue == 1 )
        {
            value = Globals.player.rate + 0.1
        }
        else
        {
            return  // ignore value == 0
        }
        
        if ( value <= 10.0 && value >= -10.0 )
        {
            Globals.player.rate = value
            
            let speedStr = String(format:"$%.2f ", Globals.player.rate)
            print(speedStr)
            
            playbackRate = Globals.player.rate
        }
    }
    
    func jogPlayer( jogScale: UInt8, jogValue: Int )
    {
    
        if ( Globals.player == nil || Globals.playerItem == nil || jogValue == 0 )
        {
            return
        }
        
        var value = jogValue
        
        if ( value >= 127 )
        {
            value = -1
        }
    
        let tracks = Globals.playerItem.asset.tracks(withMediaType: .video)
        let fps = tracks.first?.nominalFrameRate
        let duration = Globals.playerItem.asset.duration

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
                
        Globals.player!.pause()

        let currentTime = Globals.player.currentTime()
        let newTime = currentTime.seconds.advanced(by: span)
        
        let seekTime = CMTimeMakeWithSeconds(newTime, preferredTimescale: 1000 )
              
        Globals.player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
        
    }
    
    // Similar code in VideoFilters program, ContentView.swift
    
}
