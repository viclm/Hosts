//
//  AppDelegate.swift
//  Hosts
//
//  Created by viclm on 15/10/8.
//
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Insert code here to initialize your application
    if let button = statusItem.button {
      let icon = NSImage(named:NSImage.Name("AppIcon"))
      icon?.size = NSSize(width: 22, height: 22)
      button.image = icon
      button.action = #selector(activateApplication)
    }
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  @objc func activateApplication() {
    NSApp.activate(ignoringOtherApps: true)
  }
  
}

