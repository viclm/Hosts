//
//  ViewController.swift
//  Hosts
//
//  Created by viclm on 15/10/8.
//
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, NSTextViewDelegate {

    @IBOutlet weak var ruleListView: NSTableView!
    @IBOutlet var ruleContentView: NSTextView!
    
    //let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    
    let dataDir = NSHomeDirectory() + "/.hosts"
    let ruleFile = "rules.json"
    
    var originalHosts = ""
    
    struct rule {
        var name: String
        var content: String
        var editable: Bool
        var selected: Bool
        init(name: String, content: String, editable: Bool = true, selected: Bool = false) {
            self.name = name
            self.content = content
            self.editable = editable
            self.selected = selected
        }
        init?(json: AnyObject) {
            guard let name = json["name"] as? String, let content = json["content"] as? String, let editable = json["editable"] as? Bool, let selected = json["selected"] as? Bool
            else { return nil }
            self.name = name
            self.content = content
            self.editable = editable
            self.selected = selected
        }
        func toJSON() -> NSDictionary {
            var tmp = [String: AnyObject]()
            tmp["name"] = self.name
            tmp["content"] = self.content
            tmp["editable"] = self.editable
            tmp["selected"] = self.selected
            return tmp
        }
    }

    var rules = [rule]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        do {
            let manager = NSFileManager.defaultManager()
            try manager.createDirectoryAtPath(dataDir, withIntermediateDirectories: true, attributes: nil)
        
            if manager.fileExistsAtPath(dataDir + "/" + ruleFile) {
                let hostsData = try String(contentsOfFile: dataDir + "/" + ruleFile, encoding: NSUTF8StringEncoding)
                let json = try NSJSONSerialization.JSONObjectWithData(hostsData.dataUsingEncoding(NSUTF8StringEncoding)!, options: [])
                for j in json as! NSArray {
                    rules.append(rule(json: j)!)
                }
                if rules.count > 0 && rules[0].name == "/etc/hosts" {
                    rules.removeAtIndex(0)
                }
            }
        } catch {
            print("规则数据读取失败")
        }

        do {
            let currentHosts = try String(contentsOfFile: "/etc/hosts", encoding: NSUTF8StringEncoding)
            let rtrim = try NSRegularExpression(pattern: "#\\sHosts\\sRule:\\s.*", options: NSRegularExpressionOptions.DotMatchesLineSeparators)
            originalHosts = rtrim.stringByReplacingMatchesInString(currentHosts, options: [], range: NSMakeRange(0, (currentHosts as NSString).length), withTemplate: "")
            rules.insert(rule(name: "/etc/hosts", content: currentHosts, editable: false), atIndex: 0)
            saveRule()
            showRule(0)
        } catch {
            print("系统Hosts读取失败")
        }
        
        ruleListView.setDelegate(self)
        ruleListView.setDataSource(self)
        ruleContentView.delegate = self

        //let icon = NSImage(named: "AppIcon")
        //icon!.size = NSSize(width: 22, height: 22)
        //statusItem.image = icon
        //statusItem.button!.action = "openWindow"
        
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: self) as! NSTableCellView
        let r = rules[row]
        cell.textField!.stringValue = r.name
        cell.textField!.delegate = self
        if r.editable {
            if r.name == "/etc/hosts" {
                print(r)
            }
            cell.textField!.editable = true
            let checkbox = NSButton(frame: NSRect(x: 130, y: -1, width: 20, height: 20))
            checkbox.tag = row
            checkbox.setButtonType(NSButtonType.SwitchButton)
            checkbox.action = "selectRule:"
            if r.selected {
                checkbox.state = 1
            }
            cell.addSubview(checkbox)
        }
        return cell
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        let table = notification.object!
        if table.selectedRow > -1 {
            showRule(table.selectedRow)
        }
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return rules.count;
    }
    
    func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        let textField = control as! NSTextField
        var r = rules[ruleListView.selectedRow]
        r.name = textField.stringValue
        rules[ruleListView.selectedRow] = r
        saveRule()
        return true
    }
    
    func textDidChange(notification: NSNotification) {
        let textView = notification.object!
        let index = ruleListView.selectedRow
        if index > 0 {
            var r = rules[index]
            r.content = textView.string
            rules[index] = r
            saveRule()
        }
    }
    
    func showRule(index: Int) {
        ruleContentView.string = rules[index].content
        ruleContentView.editable = rules[index].editable
    }
    
    func selectRule(sender: NSButton) {
        rules[sender.tag].selected = sender.state == 1
        saveRule()
    }
    
    func saveRule() {
        do {
            var json = [AnyObject]()
            for r in rules {
                json.append(r.toJSON())
            }
            let jsonstr = try NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions.PrettyPrinted)
            try String(data: jsonstr, encoding: NSUTF8StringEncoding)!.writeToFile(dataDir + "/" + ruleFile, atomically: false, encoding: NSUTF8StringEncoding)
        }
        catch {
            print("规则写入文件失败")
        }
    }
    
    @IBAction func addRuleToolbar(sender: NSToolbarItem) {
        rules.append(rule(name: "New rule...", content: ""))
        saveRule()
        ruleListView.insertRowsAtIndexes(NSIndexSet(index: rules.count - 1), withAnimation: NSTableViewAnimationOptions.EffectNone)
        ruleListView.selectRowIndexes(NSIndexSet(index: rules.count - 1), byExtendingSelection: false)
    }
    
    @IBAction func removeRuleToolbar(sender: NSToolbarItem) {
        if ruleListView.selectedRow > 0 {
            rules.removeAtIndex(ruleListView.selectedRow)
            saveRule()
            ruleListView.removeRowsAtIndexes(ruleListView.selectedRowIndexes, withAnimation: NSTableViewAnimationOptions.EffectNone)
            ruleListView.selectRowIndexes(NSIndexSet(index: rules.count - 1), byExtendingSelection: false)
        }
    }
    
    @IBAction func saveRuleToolbar(sender: NSToolbarItem) {
        var hosts = originalHosts
        for r in rules {
            if r.selected {
                hosts += "\n# Hosts Rule: \(r.name)\n\(r.content)"
            }
        }
        var r = rules[0]
        r.content = hosts
        rules[0] = r
        ruleListView.reloadData()

        var script = "do shell script \"sudo echo '\(r.content)' | tee /etc/hosts\" with administrator privileges"
        var error: NSDictionary?
        if let scriptObj = NSAppleScript(source: script) {
            if let _: NSAppleEventDescriptor = scriptObj.executeAndReturnError(&error) {
                print("/etc/hosts 写入成功")
                do {
                    script = try String(contentsOfFile: NSBundle.mainBundle().pathForResource("flushChromeHosts", ofType: "applescript")!, encoding: NSUTF8StringEncoding)
                } catch {}
                
                if let script = NSAppleScript(source: script) {
                    if let _: NSAppleEventDescriptor = script.executeAndReturnError(&error) {
                        print("Chrome sockets 刷新成功")
                    }
                    else if (error != nil) {
                        print("Chrome sockets 刷新失败")
                    }
                }
                else {
                    print("applescript 脚本加载失败")
                }
            }
            else if (error != nil) {
                print("/etc/hosts 写入失败")
            }
        }
        else {
            print("applescript 脚本加载失败")
        }
    }

}