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
    
}
