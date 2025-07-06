//
//  NSPreferenceController.swift
//
//  Created by Björn Friedrichs on 04/05/2019.
//  Copyright © 2019 Björn Friedrichs. All rights reserved.
//

import Cocoa

protocol PreferencePane: NSViewController {
  /// This title will be displayed in the tab switcher control.
  var preferenceTabTitle: String { get }
  /// Triggered right before the pane change animation (old pane is still visible).
  func paneWillAppear(inWindowController windowController: NSPreferenceController)
  /// Triggered right before the pane change animation (pane is still visible).
  func paneWillDisappear()
  /// Triggered once animation is complete and pane is visible.
  func paneDidAppear(inWindowController windowController: NSPreferenceController)
  /// Triggered once animation is complete and pane is not longer visible.
  func paneDidDisappear()
}

extension PreferencePane {
  func paneWillAppear(inWindowController windowController: NSPreferenceController) {}
  func paneWillDisappear() {}
  func paneDidAppear(inWindowController windowController: NSPreferenceController) {}
  func paneDidDisappear() {}
}

protocol PreferenceWindowDelegate {
  func preferenceWindowWillShow(withPane pane: PreferencePane)
  func preferenceWindowWillClose(withPane pane: PreferencePane)
}

class NSPreferenceController: NSWindowController, NSWindowDelegate, NSToolbarDelegate,
  PreferenceWindowDelegate
{
  fileprivate let panes: [PreferencePane]
  fileprivate var control: NSSegmentedControl?

  fileprivate var isAnimating = false
  fileprivate var _index = 0
  var index: Int {
    return _index
  }

  init(withName: String, panes: [PreferencePane]) {
    self.panes = panes

    let size = self.panes.first!.view.frame.size
    let origin = NSMakePoint(
      NSScreen.main!.frame.width / 2 - size.width / 2,
      NSScreen.main!.frame.height / 2 - size.height / 2
    )

    let window = NSWindow(
      contentRect: NSRect(origin: origin, size: size),
      styleMask: [.closable, .miniaturizable, .titled], backing: .buffered, defer: false)

    window.title = withName
    super.init(window: window)
    window.windowController = self
    window.delegate = self
    window.titleVisibility = .hidden
    window.toolbar = NSToolbar(identifier: "mainToolbar")
    window.toolbar!.delegate = self
    window.toolbar!.centeredItemIdentifier = NSToolbarItem.Identifier(rawValue: "mainItem")
    window.toolbar!.insertItem(
      withItemIdentifier: window.toolbar!.centeredItemIdentifier!, at: 0)

    self.contentViewController = self.panes[index]
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  internal override func showWindow(_ sender: Any?) {
    self.preferenceWindowWillShow(withPane: panes[index])
    self.panes[index].paneWillAppear(inWindowController: self)
    self.panes[index].paneDidAppear(inWindowController: self)

    // Reset window origin after first load
    let size = window!.frame.size
    let origin = NSMakePoint(
      NSScreen.main!.frame.width / 2 - size.width / 2,
      NSScreen.main!.frame.height / 2 - size.height / 2
    )
    window!.setFrameOrigin(origin)

    NSApp.activate(ignoringOtherApps: true)
    super.showWindow(sender)
    self.window!.makeKeyAndOrderFront(nil)
    self.window!.orderFrontRegardless()
  }

  internal func windowWillClose(_ notification: Notification) {
    self.panes[index].paneWillDisappear()
    self.preferenceWindowWillClose(withPane: panes[index])
  }

  func preferenceWindowWillShow(withPane pane: PreferencePane) {}
  func preferenceWindowWillClose(withPane pane: PreferencePane) {}

  internal func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return [toolbar.centeredItemIdentifier!]
  }

  internal func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return [toolbar.centeredItemIdentifier!]
  }

  internal func toolbar(
    _ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
    willBeInsertedIntoToolbar flag: Bool
  ) -> NSToolbarItem? {
    if itemIdentifier == toolbar.centeredItemIdentifier {
      let labels = self.panes.map({ (pane) -> String in
        return pane.preferenceTabTitle
      })

      let item = NSToolbarItem(itemIdentifier: itemIdentifier)
      let control = NSSegmentedControl(
        labels: labels, trackingMode: .selectOne, target: self,
        action: #selector(self.changeTab))
      control.selectSegment(withTag: index)
      item.view = control

      self.control = control
      return item
    }
    return nil
  }

  internal func getWindowRect(comparedTo otherIndex: Int) -> NSRect {
    let oldContentSize = self.panes[otherIndex].view.frame.size
    let newContentSize = self.panes[index].view.fittingSize

    let frameSize = self.window!.frame.size
    let titleSize = NSMakeSize(
      frameSize.width - oldContentSize.width,
      frameSize.height - oldContentSize.height)
    let newFrameSize = NSMakeSize(
      titleSize.width + newContentSize.width,
      titleSize.height + newContentSize.height)

    // let origin = NSMakePoint(
    //   self.window!.frame.origin.x,
    //   self.window!.frame.origin.y + oldContentSize.height - newContentSize.height
    // )

    let origin = NSMakePoint(
      NSScreen.main!.frame.width / 2 - newFrameSize.width / 2,
      NSScreen.main!.frame.height / 2 - newFrameSize.height / 2
    )

    return NSRect(origin: origin, size: newFrameSize)
  }

  @objc internal func changeTab(_ control: NSSegmentedControl) {
    if index == control.indexOfSelectedItem {
      return
    }
    if self.isAnimating {
      control.selectSegment(withTag: index)
      return
    }
    let oldIndex = index
    self._index = control.indexOfSelectedItem
    self.isAnimating = true

    let oldController = self.panes[oldIndex]
    let newController = self.panes[index]

    oldController.paneWillDisappear()
    newController.paneWillAppear(inWindowController: self)

    window!.contentView = nil
    let newRect = getWindowRect(comparedTo: oldIndex)

    // Animate window frame, then swap contentViewController after animation completes
    NSAnimationContext.runAnimationGroup(
      { context in
        context.duration = 0.5
        self.window!.animator().setFrame(
          newRect, display: true, animate: true)
      },
      completionHandler: {
        self._index = control.indexOfSelectedItem
        self.contentViewController = newController
        oldController.paneDidDisappear()
        newController.paneDidAppear(inWindowController: self)
        self.isAnimating = false
      })

    // Force the window to stay key and front during the animation
    self.window?.makeKeyAndOrderFront(nil)
  }
}
