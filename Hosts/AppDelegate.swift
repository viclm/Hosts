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
  
  let statusItem = NSStatusBar.system.statusItem(withLength: -1)
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Insert code here to initialize your application
    let icon = NSImage(named: "AppIcon")
    icon!.size = NSSize(width: 22, height: 22)
    statusItem.image = icon
    statusItem.button!.action = #selector(AppDelegate.activateApplication)
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  @objc func activateApplication() {
    NSApp.activate(ignoringOtherApps: true)
  }
  
}

