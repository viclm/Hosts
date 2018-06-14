//
//  Rules.swift
//  Hosts
//
//  Created by viclm on 18/6/13.
//
//

import Foundation

struct Rule {
  var name: String
  var content: String
  var editable: Bool
  var selected: Bool
  
  init(name: String, content: String = "", editable: Bool = true, selected: Bool = true) {
    self.name = name
    self.content = content
    self.editable = editable
    self.selected = selected
  }
  
  init?(json: NSDictionary) {
    guard let name = json["name"] as? String, let content = json["content"] as? String, let editable = json["editable"] as? Bool, let selected = json["selected"] as? Bool
      else { return nil }
    self.name = name
    self.content = content
    self.editable = editable
    self.selected = selected
  }
  
  func toJSON() -> NSDictionary {
    return [
      "name": self.name,
      "content": self.content,
      "editable": self.editable,
      "selected": self.selected
    ]
  }
}

let rulesStoreKey = "rules"

struct Rules {
  
  var list: [Rule] {
    get {
      let list = UserDefaults.standard.array(forKey: rulesStoreKey) as! [NSDictionary]
      return list.map {
        Rule(json: $0)!
      }
    }
  }
  
  var count: Int {
    get {
      return list.count
    }
  }
  
  init() {
    if UserDefaults.standard.array(forKey: rulesStoreKey) == nil {
      let rule = Rule(name: "/etc/hosts")
      UserDefaults.standard.set([rule.toJSON()], forKey: rulesStoreKey)
    }
  }
  
  func index(_ index: Int) -> Rule? {
    guard list.indices.contains(index) else {
      return nil
    }
    return list[index]
  }
  
  func add(_ rule: Rule) {
    var list = UserDefaults.standard.array(forKey: rulesStoreKey) as! [NSDictionary]
    list.append(rule.toJSON())
    UserDefaults.standard.set(list, forKey: rulesStoreKey)
  }
  
  func set(_ index: Int, _ rule: Rule) {
    var list = UserDefaults.standard.array(forKey: rulesStoreKey) as! [NSDictionary]
    guard list.indices.contains(index) else {
      return
    }
    list[index] = rule.toJSON()
    UserDefaults.standard.set(list, forKey: rulesStoreKey)
  }
  
  func delete(_ index: Int) {
    var list = UserDefaults.standard.array(forKey: rulesStoreKey) as! [NSDictionary]
    guard list.indices.contains(index) else {
      return
    }
    list.remove(at: index)
    UserDefaults.standard.set(list, forKey: rulesStoreKey)
  }
  
}
