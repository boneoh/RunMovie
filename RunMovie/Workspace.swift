//
//  ActiveFilters.swift
//  CustomCompositor
//
//  Created by peterappleby on 3/29/22.
//  Copyright © 2022 Peter M. Appleby aka Boneoh.  All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import CoreImage
import os

public class Workspace: Codable {

    // IMPORTANT NOTE!
    
    // The workspace is saved to and loaded from JSON files.
    // Many of the class objects saved contain ENUM values.
    
    // DO NOT CHANGE ENUMs! Doing so will break backwards
    // compatibility in the saved workspace files.
    // Add new entries to the end of the list, just before
    // the .none or .unknown entry.
    
    // Do NOT remove existing enums or change the sequence
    // of existing enums!
    
    // Also note the presence of "init( from decoder" in the
    // class code to handle default values for new
    // parameters as they are added. This will allow old
    // JSON files to be read and default values applied for
    // properties that have been added and do not exist
    // in older JSON files.
    
    // DON'T BREAK BACKWARDS COMPATIBILITY!
    
    // Test your changes with old workspace JSON files
    // after you add new properties, enums, etc.

    
   public var movieFileURL:  URL? =  nil
    
   public var playLoop: Bool = true
   public var isMuted: Bool = true
    
   public var markIn: Int64 = 0
   public var markOut: Int64 = 0
   public var currentTime: Int64 = 0
   public var playbackSpeed: Float

    
   // when adding new properties, if the value must be saved to the workspace
   // the property must be added to the coding keys and init(from decoder
    
    enum CodingKeys: String, CodingKey {
         
        case playLoop
        case isMuted
        case markIn
        case markOut
        case currentTime
        case playbackSpeed
        
    }
    
    required public init(from decoder: Decoder) throws {
        
        Globals.logger.debug("Workspace - init(from decoder starting")
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
                
        self.playLoop = try container.decodeIfPresent( Bool.self, forKey: .playLoop) ??  true
        self.isMuted = try container.decodeIfPresent( Bool.self, forKey: .isMuted) ??  true
        self.markIn = try container.decodeIfPresent( Int64.self, forKey: .markIn) ?? 0
        self.markOut = try container.decodeIfPresent( Int64.self, forKey: .markOut) ?? -1
        self.currentTime = try container.decodeIfPresent( Int64.self, forKey: .currentTime) ?? 0
        self.playbackSpeed = try container.decodeIfPresent( Float.self, forKey: .playbackSpeed) ?? 1.0

        let markInTemp = CMTime(value: self.markIn, timescale: 1000, flags: .valid, epoch: 0)
        Globals.setMarkIn(startTime: markInTemp)
        
        let markOutTemp = CMTime(value: self.markOut, timescale: 1000, flags: .valid, epoch: 0)
        Globals.setMarkOut(endTime: markOutTemp)
        
        // pause()
        
        // let currentTemp = CMTime(value: self.currentTime, timescale: 1000, flags: .valid, epoch: 0)
        // Globals.player.seek(to: currentTemp, toleranceBefore: .zero, toleranceAfter: .zero)
        
        Globals.player.rate = self.playbackSpeed
        playbackRate = self.playbackSpeed
        
        Globals.logger.debug("Workspace - init(from decoder completed")
    }
    
    
    required public init() {
        self.playLoop = true
        self.markIn = 0
        self.markOut = -1
        self.currentTime = 0
        self.playbackSpeed = 1.0
    }
       
    /*
    func getTimeRange( ) -> CMTimeRange
    {
        let timeRange = CMTimeRangeFromTimeToTime(start: markIn, end: markOut)
        return timeRange
    }
    */
    
}
