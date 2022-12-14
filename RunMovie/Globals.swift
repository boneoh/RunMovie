//
//  Globals.swift
//  RunMovie
//
//  Created by peterappleby on 3/1/22.
//

import Foundation
import AVKit
import AVFoundation
import os
import Network

public var playerItem: AVPlayerItem!
public var player: AVPlayer!
public var movieFilepath: String = ""
public var isWindowCreated: Bool = false
public var isWindowFullScreen: Bool = false
public var mainScreenName: String = ""
public var currentScreenName: String? = ""
// public var processingHomeCommand: Bool = false
public var logger: Logger = Logger(subsystem: "com.applebysw.RunMovie", category: "debug")


public let portA: NWEndpoint.Port = 10001
public let portB: NWEndpoint.Port = 10002

public var port: NWEndpoint.Port = portA

public func handleMIDIdata( cmd: UInt8, note: UInt8, knob: UInt8 )
{
    
    switch ( cmd )
    {
        case 0x90:      // begin note
            
            switch ( note )
            {
                case 0x2C:      // rewind port A
                    
                    if ( port == portA )
                    {
                        player!.pause()
                        player!.seek(to: .zero)
                    }
                    
                case 0x2D:      // stop port A
                    
                    if ( port == portA )
                    {
                        player!.pause()
                    }
                    
                case 0x2E:      // play port A
                    
                    if ( port == portA )
                    {
                        player!.play()
                    }
                    
                case 0x2F:      // rewind port B
                    
                    if ( port == portB )
                    {
                        player!.pause()
                        player!.seek(to: .zero)
                    }
                    
                case 0x30:      // stop port B
                    
                    if ( port == portB )
                    {
                        player!.pause()
                    }
                    
                case 0x31:      // play port B
                    
                    if ( port == portB )
                    {
                        player!.play()
                    }
                    
                case 0x32:      // rewind both A + B
                    
                    player!.pause()
                    player.seek(to: .zero)
                    
                case 0x33:      // play both A + B
                    
                    player!.play()
                    
                default:
                    
                    return
            }
            
        case 0xB0:      // knob
            
            return      // ignore for now
            
        case 0xFA:      // start
            
            player!.play()
            
        case 0xFC:      // stop
            
            player!.pause()
            
        default:
            return
    }
    
    let cmdStr = String(format:"$%02X ", cmd)
    let noteStr = String(format:"$%02X ", note)
    let knobStr = String(format:"$%02X ", knob)
    
    let dumpStr = cmdStr + " " + noteStr + " " + knobStr
    
    print( dumpStr )
}
