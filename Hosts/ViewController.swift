//
//  ViewController.swift
//  Hosts
//
//  Created by viclm on 15/10/8.
//
//

import Cocoa

class ViewController: NSViewController {
  
  @IBOutlet weak var ruleListView: NSTableView!
  @IBOutlet var ruleContentView: NSTextView!
  
  var originalHosts = ""
  
  var rules = Rules()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    guard let hosts = readSystemHosts() else {
      let alert = NSAlert()
      alert.messageText = "Oops, something went to wrong!"
      alert.informativeText = "Try to reload later."
      alert.alertStyle = .warning
      alert.addButton(withTitle: "Ok")
      alert.runModal()
      return
    }
    
    originalHosts = hosts.original
    rules.set(0, Rule(name: "/etc/hosts", content: hosts.current, editable: false, selected: false))
    
    ruleListView.delegate = self
    ruleListView.dataSource = self
    ruleContentView.delegate = self

    display(0)
  }
  
  fileprivate func readSystemHosts() -> (current: String, original: String)? {
    do {
      let currentHosts = try String(contentsOfFile: "/etc/hosts", encoding: String.Encoding.utf8)
      let rtrim = try NSRegularExpression(pattern: "#\\sHosts\\sRule:\\s.*", options: NSRegularExpression.Options.dotMatchesLineSeparators)
      originalHosts = rtrim.stringByReplacingMatches(in: currentHosts, options: [], range: NSMakeRange(0, (currentHosts as NSString).length), withTemplate: "")
      return (currentHosts, originalHosts)
    } catch {
      return nil
    }
  }
  
  func display(_ index: Int) {
    guard let r = rules.index(index) else {
      return
    }
    ruleContentView.string = r.content
    ruleContentView.isEditable = r.editable
  }
  
}

extension ViewController: NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return rules.count;
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
    guard let r = rules.index(row) else {
      return nil
    }
    
    cell.textField!.stringValue = r.name
    cell.textField!.delegate = self
    if r.editable {
      cell.textField!.isEditable = true
      let checkbox = NSButton(frame: NSRect(x: 130, y: -1, width: 20, height: 20))
      checkbox.tag = row
      checkbox.setButtonType(NSButton.ButtonType.switch)
      checkbox.action = #selector(ViewController.select(_:))
      if r.selected {
        checkbox.state = NSControl.StateValue.on
      }
      cell.addSubview(checkbox)
    }
    return cell
  }
  
  func tableViewSelectionDidChange(_ notification: Notification) {
    let table = notification.object!
    if (table as AnyObject).selectedRow > -1 {
      display((table as AnyObject).selectedRow)
    }
  }
  
  func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
    let textField = control as! NSTextField
    guard var r = rules.index(ruleListView.selectedRow) else {
      return false
    }
    r.name = textField.stringValue
    rules.set(ruleListView.selectedRow, r)
    return true
  }
  
  @objc func select(_ sender: NSButton) {
    guard var r = rules.index(sender.tag) else {
      return
    }
    r.selected = sender.state == NSControl.StateValue.on
    rules.set(sender.tag, r)
  }
  
}

extension ViewController: NSTextViewDelegate {
  
  func textDidChange(_ notification: Notification) {
    let textView = notification.object!
    guard var r = rules.index(ruleListView.selectedRow) else {
      return
    }
    r.content = (textView as AnyObject).string
    rules.set(ruleListView.selectedRow, r)
  }
  
}

extension ViewController: NSUserNotificationCenterDelegate {
  
  func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
    return true
  }
  
  func notify(_ message: String) {
    let userNotification = NSUserNotification()
    userNotification.title = "Hosts"
    userNotification.informativeText = message
    
    NSUserNotificationCenter.default.delegate = self
    NSUserNotificationCenter.default.deliver(userNotification)
  }
  
  func runAppleScript(_ source: String) -> Bool {
    let script = "do shell script \"\(source)\" with administrator privileges"
    
    guard let scriptObject = NSAppleScript(source: script) else {
      return false
    }
    
    var scriptError: NSDictionary?
    scriptObject.executeAndReturnError(&scriptError)
  
    return scriptError == nil
  }
  
  @IBAction func addRuleToolbar(_ sender: NSToolbarItem) {
    rules.add(Rule(name: "New rule..."))
    ruleListView.insertRows(at: IndexSet(integer: rules.count - 1), withAnimation: NSTableView.AnimationOptions())
    ruleListView.selectRowIndexes(IndexSet(integer: rules.count - 1), byExtendingSelection: false)
  }
  
  @IBAction func removeRuleToolbar(_ sender: NSToolbarItem) {
    if ruleListView.selectedRow > 0 {
      rules.delete(ruleListView.selectedRow)
      ruleListView.removeRows(at: ruleListView.selectedRowIndexes, withAnimation: NSTableView.AnimationOptions())
      ruleListView.selectRowIndexes(IndexSet(integer: rules.count - 1), byExtendingSelection: false)
    }
  }
  
  @IBAction func saveRuleToolbar(_ sender: NSToolbarItem) {
    var hosts = originalHosts
    
    for r in rules.list {
      if r.selected {
        hosts += "# Hosts Rule: \(r.name)\n\(r.content)\n"
      }
    }
    
    let result = runAppleScript("sudo echo '\(hosts)' | tee /etc/hosts; sudo killall -HUP mDNSResponder; sudo killall mDNSResponderHelper; sudo dscacheutil -flushcache")
    
    if result {
      guard var r = rules.index(0) else {
        return
      }
      r.content = hosts
      rules.set(0, r)
      if ruleListView.selectedRow == 0 {
        display(0)
      }
      notify("Success to apply rules")
    }
    else {
      notify("Fail to apply rules")
    }
    
  }
  
}
