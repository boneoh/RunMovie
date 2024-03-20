//
//  WindowController.swift
//  RunMovie
//
//  Created by peterappleby on 3/1/22.
//

import Cocoa
import AVKit
import AVFoundation

class WindowController: NSWindowController, NSWindowDelegate {
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
 
        Globals.logger.log("*** In WindowController windowDidLoad")
        
        showWindow (nil)
        
        Globals.windowController = self
        
        self.window?.title = Globals.movieFilepath
        
 
        window!.titleVisibility = .hidden
        window!.titlebarAppearsTransparent = true

        window!.styleMask = [window!.styleMask,  NSWindow.StyleMask.fullSizeContentView]
        
        Globals.windowSetDisplay()
        
        Globals.windowWasLoaded = true
              
        let currentTemp = CMTime(value: Globals.workspace.currentTime, timescale: 1000, flags: .valid, epoch: 0)
        Globals.player.seek(to: currentTemp, toleranceBefore: .zero, toleranceAfter: .zero)
        
        /*
        let dx = 1920.0 / 2.0
        let dy = 1080.0 / 2.0
        
        let screens = NSScreen.screens
        var pos = NSPoint()
        pos.x = screens[0].visibleFrame.midX - dx
        pos.y = screens[0].visibleFrame.midY - dy
        self.window?.setFrameOrigin(pos)
        */
        
    }
    
    func windowDidEnterFullScreen(_ notification: Notification) {
        Globals.logger.log("*** In WindowController windowDidEnterFullScreen - set isWindowFullScreen = true")
        Globals.isWindowFullScreen = true
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        Globals.logger.log("*** In WindowController windowDidExitFullScreen - isWindowFullScreen = false")
        Globals.isWindowFullScreen = false
        
        checkFullScreen()
    }
 
 
    func windowDidChangeScreen(_ notification: Notification) {

        // need to test if the window is somewhere on the main screen or not.
        // most of the obvious checks refer to the display receiving the mouse input, not the window display.
        
        // current middle of our screen
        

        let currentDisplay = NSApplication.shared.mainWindow?.screen
        let name = currentDisplay?.localizedName ?? "?"
        let x = currentDisplay?.visibleFrame.midX ?? -1
        let y = currentDisplay?.visibleFrame.midY ?? -1
        
        let mainDisplay = NSScreen.screens[0]
        
        Globals.logger.log("*** In WindowController windowDidChangeScreenscreen main    display is: \(mainDisplay.localizedName, privacy: .public)")
        Globals.logger.log("*** In WindowController windowDidChangeScreenscreen current display is: \(name, privacy: .public)")
        
        if x >= mainDisplay.visibleFrame.minX && x <= mainDisplay.visibleFrame.maxX &&
           y >= mainDisplay.visibleFrame.minY && y <= mainDisplay.visibleFrame.maxY
        {
            Globals.logger.log("*** In WindowController windowDidChangeScreen - window is on main display:  \(mainDisplay.localizedName, privacy: .public)")
            return
        }
        
        Globals.logger.log("*** In WindowController windowDidChangeScreen - window is NOT on main display:  \(mainDisplay.localizedName, privacy: .public)")
        
        // make the window full screen without menu bar etc.
                
        checkFullScreen()
          
        // Globals.viewController?.goToBegin()
        
        /*
        Globals.player!.pause()
        Globals.player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        */
        
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
         
            logger.log("*** In WindowController windowDidChangeScreen - asyncAfter invoke player.play ")
         
            player.play()       // Code you want to be delayed
        }
         */
        
        
    }
    
    func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
        
        Globals.logger.log("*** In WindowController window")
        
        // pma 3/20/2024 Issue with display moved down. Added .autoHideDock, did not work, was worse! Menu bar appeared!

        return [ .fullScreen, .hideMenuBar, .hideDock, .autoHideToolbar ]
        // return [.autoHideToolbar, .autoHideMenuBar, .fullScreen ]

        // return [.autoHideToolbar, .autoHideMenuBar, .fullScreen, .autoHideDock]
    }
    
    func checkFullScreen() {
        
        Globals.logger.log("*** In WindowController checkFullScreen")
        
        /*
        if processingHomeCommand == true
        {
            logger.log("*** In WindowController checkFullScreen - processingHomeCommand == true")
            return
        }
        */
        
        Globals.isWindowFullScreen = window!.styleMask.contains(.fullScreen)
        
        if Globals.isWindowFullScreen == true
        {
            Globals.logger.log("*** In WindowController checkFullScreen - isWindowFullScreen == true")
            return
        }
        
        if Globals.isWindowCreated == true
        {
            Globals.logger.log("*** In WindowController checkFullScreen - isWindowCreated == true")
            return
        }
        
       
        Globals.logger.log("*** In WindowController checkFullScreen - isWindowFullScreen == false")
        
        if NSApplication.shared.mainWindow != nil
        {
            Globals.logger.log("*** In WindowController checkFullScreen - set isWindowFullScreen = true")
            
            Globals.isWindowFullScreen = true
            
            Globals.player!.pause()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                
                Globals.logger.log("*** In WindowController checkFullScreen - setting toggleFullScreen(true)")
                
                NSApplication.shared.mainWindow?.toggleFullScreen(true)
                               
                let currentTemp = CMTime(value: Globals.workspace.currentTime, timescale: 1000, flags: .valid, epoch: 0)
                Globals.player.seek(to: currentTemp, toleranceBefore: .zero, toleranceAfter: .zero)
                
                // NSCursor.hide()
            }

        }
 
    }
    
}
