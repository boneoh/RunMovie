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

