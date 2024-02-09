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
import Combine

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
    
    public static var workspace: Workspace = Workspace()        // $$$ 2/6/2024
    public static var workspaceFilepath: String = ""            // $$$ 2/6/2024
    public static var windowWasLoaded: Bool = false             // $$$ 2/7/2024

   
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
    
    
    // these are invoked by the asset loading process
    
    static func setMarkIn( startTime: CMTime )
    {
        Globals.workspace.markIn = startTime.value
    }
    
    static func setMarkOut( endTime: CMTime )
    {
        Globals.workspace.markOut = endTime.value
    }
    
    // these are invoked from the menu
    
    static func setMarkIn( )
    {
        Globals.viewController?.setMarkIn()
    }
    
    static func setMarkOut( )
    {
        Globals.viewController?.setMarkOut()
    }
    
    static func GoToIn(  )
    {
        Globals.viewController?.setMarkIn()
    }
    
    static func GoToOut(  )
    {
        Globals.viewController?.setMarkOut()
    }
    
    static func clearIn(  )
    {
        Globals.viewController?.clearMarkIn()
    }
    
    static func clearOut(  )
    {
        Globals.viewController?.clearMarkOut()
    }
    
    static func clearBoth( )
    {
        Globals.viewController?.clearBothMarks()
    }
    
    static func setPlaybackSpeed( speedValue: Int  )
    {
        // $$$ Copied from MIDI file.
        
        // set playback speed and direction

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
            Globals.workspace.playbackSpeed = playbackRate
            
            Globals.viewController!.saveWorkspace()
        }
        
    }
    
}
