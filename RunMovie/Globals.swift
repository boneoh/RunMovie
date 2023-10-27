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

public class Globals
{
    
    public static var playerItem: AVPlayerItem!
    public static var player: AVPlayer!
    public static var movieFilepath: String = ""
    public static var movieFileURL: URL!
    public static var isWindowCreated: Bool = false
    public static var isWindowFullScreen: Bool = false
    public static var mainScreenName: String = ""
    public static var currentScreenName: String? = ""
 
    public static var logger: Logger = Logger(subsystem: "com.applebysw.RunMovie", category: "debug")
    
    /*
        Removed UDP stuff, now using MIDI and keyboard
     
    public static let portA: NWEndpoint.Port = 10001
    public static let portB: NWEndpoint.Port = 10002
    
    public static var port: NWEndpoint.Port?
    */
    
    public static var viewController: ViewController?
    public static var windowController: NSWindowController?
    
    public static var targetScreen: NSScreen?
    
    public static func windowSetDisplay( ) {
        
        var screen = Globals.targetScreen
        
        if screen == nil
        {
            Globals.logger.log("*** In Globals windowSetDisplay - windowSetDisplay - targetScreen is nil")
            
            screen = NSScreen.screens[0]
        }
 
        let displayName = screen!.localizedName
        Globals.logger.log("*** In Globals windowSetDisplay - windowSetDisplay =  \(displayName, privacy: .public)")
        
        let dx = 1920.0 / 2.0
        let dy = 1080.0 / 2.0
        
        var pos = NSPoint()
        pos.x = screen!.visibleFrame.midX - dx
        pos.y = screen!.visibleFrame.midY - dy
        
        Globals.windowController?.window?.setFrameOrigin(pos)
 
    }
}
