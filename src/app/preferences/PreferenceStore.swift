//
//  PreferencesStore.swift
//  vechseler
//
//  Created by Björn Friedrichs on 02/05/2019.
//  Copyright © 2019 Björn Friedrichs. All rights reserved.
//

import Cocoa
import ServiceManagement

class PreferenceStore {
  fileprivate static var _instance: PreferenceStore?
  static var shared: PreferenceStore {
    guard let instance = PreferenceStore._instance else {
      PreferenceStore._instance = PreferenceStore()
      return PreferenceStore._instance!
    }
    return instance
  }

  private var _mainSequence = [KeyHandler.FlagAsInt.command.rawValue, 48]
  var mainSequence: [Int64] {
    get {
      return _mainSequence
    }
    set {
      _mainSequence = newValue

      let delegate = NSApp.delegate as! AppDelegate
      delegate.keyHandler!.removeEventListeners(key: .main)
      delegate.addMainListener(forSequence: newValue)
      DispatchQueue.main.async {

        UserDefaults.standard.set(
          newValue, forKey: "\(Bundle.main.bundleIdentifier!).mainSequence")
      }
    }
  }

  private var _reverseSequence = [
    KeyHandler.FlagAsInt.command.rawValue, KeyHandler.FlagAsInt.shift.rawValue, 48,
  ]
  var reverseSequence: [Int64] {
    get {
      return _reverseSequence
    }
    set {
      _reverseSequence = newValue

      let delegate = NSApp.delegate as! AppDelegate
      delegate.keyHandler!.removeEventListeners(key: .mainReverse)
      delegate.addReverseListener(forSequence: newValue)
      DispatchQueue.main.async {
        UserDefaults.standard.set(
          newValue, forKey: "\(Bundle.main.bundleIdentifier!).reverseSequence")
      }
    }
  }

  private var _cycleBackwardsWithShift = true
  var cycleBackwardsWithShift: Bool {
    get {
      return _cycleBackwardsWithShift
    }
    set {
      _cycleBackwardsWithShift = newValue

      let delegate = NSApp.delegate as! AppDelegate
      delegate.cycleBackwardsWithShift = newValue
      DispatchQueue.main.async {

        UserDefaults.standard.set(
          newValue, forKey: "\(Bundle.main.bundleIdentifier!).cycleBackwardsWithShift")
      }
    }
  }

  private var _iconSize = 100
  var iconSize: Int {
    get {
      return _iconSize
    }
    set {
      _iconSize = newValue

      let delegate = NSApp.delegate as! AppDelegate

      DispatchQueue.main.async {
        delegate.previewWindow.updateApplicationViews()
        UserDefaults.standard.set(
          newValue, forKey: "\(Bundle.main.bundleIdentifier!).iconSize")
      }
    }
  }

  private var _enableMouseSelection = true
  var enableMouseSelection: Bool {
    get {
      return _enableMouseSelection
    }
    set {
      _enableMouseSelection = newValue

      DispatchQueue.main.async {
        UserDefaults.standard.set(
          newValue, forKey: "\(Bundle.main.bundleIdentifier!).enableMouseSelection")
      }
    }
  }

  private var _previewY = 0
  var previewY: Int {
    get {
      return _previewY
    }
    set {
      _previewY = newValue

      DispatchQueue.main.async {
        UserDefaults.standard.set(
          newValue, forKey: "\(Bundle.main.bundleIdentifier!).previewY")
      }
    }
  }

  private var _openAtLogin = false
  var openAtLogin: Bool {
    get {
      return _openAtLogin
    }
    set {
      _openAtLogin = newValue
      DispatchQueue.main.async {
        UserDefaults.standard.set(
          newValue, forKey: "\(Bundle.main.bundleIdentifier!).openAtLogin")
        // Register/unregister with macOS
        PreferenceStore.setOpenAtLogin(enabled: newValue)
      }
    }
  }

  static func setOpenAtLogin(enabled: Bool) {
    if #available(macOS 13.0, *) {
      // Use SMAppService for modern macOS
      do {
        if enabled {
          try ServiceManagement.SMAppService.mainApp.register()
        } else {
          try ServiceManagement.SMAppService.mainApp.unregister()
        }
      } catch {
        print("Failed to update login item: \(error)")
      }
    } else {
      // Fallback for older macOS (optional, can use SMLoginItemSetEnabled if helper exists)
    }
  }

  fileprivate init() {
    _mainSequence =
      UserDefaults.standard.object(forKey: "\(Bundle.main.bundleIdentifier!).mainSequence")
      as? [Int64] ?? _mainSequence
    _reverseSequence =
      UserDefaults.standard.object(forKey: "\(Bundle.main.bundleIdentifier!).reverseSequence")
      as? [Int64] ?? _reverseSequence

    _cycleBackwardsWithShift =
      UserDefaults.standard.object(
        forKey: "\(Bundle.main.bundleIdentifier!).cycleBackwardsWithShift") as? Bool
      ?? _cycleBackwardsWithShift

    _iconSize =
      UserDefaults.standard.object(forKey: "\(Bundle.main.bundleIdentifier!).iconSize")
      as? Int ?? _iconSize

    _previewY =
      UserDefaults.standard.object(forKey: "\(Bundle.main.bundleIdentifier!).previewY")
      as? Int ?? _previewY

    _enableMouseSelection =
      UserDefaults.standard.object(
        forKey: "\(Bundle.main.bundleIdentifier!).enableMouseSelection") as? Bool
      ?? _enableMouseSelection

    _openAtLogin =
      UserDefaults.standard.object(
        forKey: "\(Bundle.main.bundleIdentifier!).openAtLogin") as? Bool
      ?? _openAtLogin
  }
}
