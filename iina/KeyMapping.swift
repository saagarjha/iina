//
//  KeyMap.swift
//  iina
//
//  Created by lhc on 12/12/2016.
//  Copyright © 2016 lhc. All rights reserved.
//

import Foundation

class KeyMapping {

  static let prettyKeySymbol = [
    "META": "⌘",
    "ENTER": "↩︎",
    "SHIFT": "⇧",
    "ALT": "⌥",
    "CTRL":"⌃",
    "SPACE": "␣",
    "BS": "⌫",
    "DEL": "⌦",
    "TAB": "⇥",
    "ESC": "⎋",
    "UP": "↑",
    "DOWN": "↓",
    "LEFT": "←",
    "RIGHT" : "→",
    "PGUP": "⇞",
    "PGDWN": "⇟",
    "HOME": "↖︎",
    "END": "↘︎",
    "PLAY": "▶︎\u{2006}❙\u{200A}❙",
    "PREV": "◀︎◀︎",
    "NEXT": "▶︎▶︎"
  ]

  var isIINACommand: Bool

  var key: String

  var action: [String]

  private var privateRawAction: String

  var rawAction: String {
    set {
      if newValue.hasPrefix("@iina") {
        privateRawAction = newValue.substring(from: newValue.index(newValue.startIndex, offsetBy: 5)).trimmingCharacters(in: .whitespaces)
        action = rawAction.components(separatedBy: " ")
        isIINACommand = true
      } else {
        privateRawAction = newValue
        action = rawAction.components(separatedBy: " ")
        isIINACommand = false
      }
    }
    get {
      return privateRawAction
    }
  }

  var comment: String?

  var readableAction: String {
    get {
      let joined = action.joined(separator: " ")
      return isIINACommand ? ("@iina " + joined) : joined
    }
  }

  var prettyKey: String {
    get {
      return key
        .components(separatedBy: "+")
        .map { token -> String in
          let uppercasedToken = token.uppercased()
          if let symbol = KeyMapping.prettyKeySymbol[uppercasedToken] {
            return symbol
          } else if let origToken = KeyCodeHelper.reversedKeyMapForShift[token] {
            return KeyMapping.prettyKeySymbol["SHIFT"]! + origToken.uppercased()
          } else {
            return uppercasedToken
          }
        }.joined(separator: "")
    }
  }

  var prettyCommand: String {
    return KeyBindingTranslator.readableCommand(fromAction: action, isIINACommand: isIINACommand)
  }

  init(key: String, rawAction: String, isIINACommand: Bool = false, comment: String? = nil) {
    self.key = key
    self.privateRawAction = rawAction
    self.action = rawAction.components(separatedBy: " ")
    self.isIINACommand = isIINACommand
    self.comment = comment
  }

  static func parseInputConf(_ path: String) -> [KeyMapping]? {
    let reader = StreamReader(path: path)
    var mapping: [KeyMapping] = []
    var isIINACommand = false
    while var line: String = reader?.nextLine() {      // ignore empty lines
      if line.isEmpty { continue }
      if line.hasPrefix("#@iina") {
        // extended syntax
        isIINACommand = true
        line = line.substring(from: line.index(line.startIndex, offsetBy: 6))
      } else if line.hasPrefix("#") {
        // igore comment
        continue
      }
      // remove inline comment
      if let sharpIndex = line.characters.index(of: "#") {
        line = line.substring(to: sharpIndex)
      }
      // split
      let splitted = line.characters.split(separator: " ", maxSplits: 1)
      if splitted.count < 2 {
        return nil
      }
      let key = String(splitted[0]).trimmingCharacters(in: .whitespaces)
      let action = String(splitted[1]).trimmingCharacters(in: .whitespaces)

      mapping.append(KeyMapping(key: key, rawAction: action, isIINACommand: isIINACommand, comment: nil))
    }
    return mapping
  }

  static func generateConfData(from mappings: [KeyMapping]) -> String {
    var result = "# Generated by IINA\n\n"
    mappings.forEach { km in
      if km.isIINACommand {
        result += "#@iina \(km.key) \(km.action.joined(separator: " "))\n"
      } else {
        result += "\(km.key) \(km.action.joined(separator: " "))\n"
      }
    }
    return result
  }
}
