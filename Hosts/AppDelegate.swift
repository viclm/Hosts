//
//  AppDelegate.swift
//  Hosts
//
//  Created by 刘明 on 15/10/8.
//
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        let icon = NSImage(named: "AppIcon")
        icon!.size = NSSize(width: 22, height: 22)
        statusItem.image = icon
        statusItem.button!.action = "activateApplication"
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func activateApplication() {
        NSApp.activateIgnoringOtherApps(true)
    }

}

