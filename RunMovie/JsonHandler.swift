//
//  JsonHandler.swift
//  CustomCompositor
//
//  Created by peterappleby on 3/25/22.
//  Copyright © 2022 Peter M. Appleby aka Boneoh.  All rights reserved.
//

import Foundation
import SwiftUI

class JsonHandler
{
    
    static func writeJSON<T: Codable>(object: T, url: URL? ) {

        var fileURL = url
        
        let typeName = String(describing: type(of: T.self))

        do {
            
            if ( fileURL == nil )
            {
                    
                // prompt for file to write to

                let dialog = NSSavePanel()
                
                dialog.title = "Save \(typeName) to file"
                
                /*
                if ( Globals.workspace.lastWorkspacePath.count > 0 )
                {
                    dialog.directoryURL = NSURL.fileURL( withPath: Globals.workspace.lastWorkspacePath, isDirectory: true)
                }
                */
                
                dialog.showsResizeIndicator = true
                dialog.showsHiddenFiles = true
                dialog.canCreateDirectories = true
                
                dialog.allowedContentTypes = [.json]
                // dialog.allowedFileTypes = ["json"]
                
                dialog.isExtensionHidden = false
                dialog.allowsOtherFileTypes = false
                
                if dialog.runModal() == .OK {
                    fileURL  = dialog.url
                }
                else
                {
                    // User clicked on "Cancel"
                    return
                }
            }
                
            // Globals.workspace.lastWorkspacePath = fileURL!.path
            // Globals.saveUserDefaults()
                
            // save the workspace to the url
                
            let encoder = try JSONEncoder().encode(object)

            try encoder.write(to: fileURL!)
                
            Globals.logger.info("Wrote \(typeName) info to file \(fileURL!.path)")
           
        } catch {
            Globals.logger.error("JsonHandler.writeJSON error \(typeName)")
        }
    }

    static func readJSON<T: Codable>( object: T.Type, url: URL?  ) -> T? {
                
        var fileURL = url
        
        let typeName = String(describing: type(of: T.self))
        
        do {
            
            if ( fileURL == nil )
            {
                 
                 // prompt for file to read from
                 
                 let dialog = NSOpenPanel()
                 
                 dialog.title = "Open \(typeName) from file"
                 dialog.message = "Open \(typeName) from file"
                 
                 /*
                 if ( Globals.workspace.lastWorkspacePath.count > 0 )
                 {
                     dialog.directoryURL = NSURL.fileURL( withPath: Globals.workspace.lastWorkspacePath, isDirectory: true)
                 }
                 */
                
                 dialog.showsResizeIndicator = true
                 dialog.showsHiddenFiles = true
                 dialog.canCreateDirectories = true
                 
                 dialog.allowedContentTypes = [.json]
                 // dialog.allowedFileTypes = ["json"]
                 
                 dialog.isExtensionHidden = false
                 dialog.allowsOtherFileTypes = true
                 
                 if dialog.runModal() == .OK {
                     
                     fileURL  = dialog.url!
                 

                 } else {
                     // User clicked on "Cancel"
                     return nil
                 }
            }
            let fileMgr = FileManager()
            var isDir : ObjCBool = true
            
            let path  = fileURL?.path
            if ( path!.count <= 0 || fileMgr.fileExists(atPath: path!, isDirectory:  &isDir) != true )
            {
                return nil
            }
                
            // Globals.workspace.lastWorkspacePath = fileURL!.path
            // Globals.saveUserDefaults()
            
            let data = try Data(contentsOf: fileURL!)

            Globals.logger.debug("JsonHandler.readJSON - starting")
            
            let object = try JSONDecoder().decode(T.self, from: data)

            Globals.logger.debug("JsonHandler.readJSON - starting - Read \(typeName) info from file \(fileURL!.path)")
            
            return object
            
        } catch {
            Globals.logger.error("JsonHandler.readJSON error \(typeName)")
            return nil
        }
    }

    

    static func writeJSON<T: Codable>(fileURL: URL, object: T) {
        let typeName = String(describing: type(of: T.self))
        
        do {
            let encoder = try JSONEncoder().encode(object)

            try encoder.write(to: fileURL)
            
            Globals.logger.info("Wrote info to file \(fileURL.path)")
            
        } catch {
            Globals.logger.error("JsonHandler.writeJSON error \(typeName)")
        }
    }

    static func readJSON<T: Codable>(fileURL: URL, _ object: T.Type) -> T? {
        let typeName = String(describing: type(of: T.self))
        
        do {
             let data = try Data(contentsOf: fileURL)

             let object = try JSONDecoder().decode(T.self, from: data)

             Globals.logger.info("Read info from file \(fileURL.path)")
             
            return object
        } catch {
            Globals.logger.error("JsonHandler.readJSON error \(typeName)")
            return nil
        }
    }
        
}
