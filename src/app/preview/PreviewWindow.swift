//
//  PreviewWindow.swift
//  vechseler
//
//  Created by Björn Friedrichs on 27/04/2019.
//  Copyright © 2019 Björn Friedrichs. All rights reserved.
//

import Cocoa

class ContentView: NSView {
  override var isOpaque: Bool {
    return false
  }

  override var allowsVibrancy: Bool {
    return true
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    // self.layer?.backgroundColor = NSColor.clear.cgColor
    // self.wantsLayer = true
  }

}

class PreviewWindow: NSWindow {
  let mainPadding: CGFloat = 30
  let cellMargin: CGFloat = 20

  var moveStopTimer: Timer?

  let backgroundView: NSVisualEffectView
  let applicationView: ResizingView
  let selectionView: NSVisualEffectView

  var windowList: [QSWindow] = []
  var selected = 0

  var trackingArea: NSTrackingArea?

  override var canBecomeKey: Bool {
    return true
  }

  override var canBecomeMain: Bool {
    return true
  }

  convenience init() {
    self.init(
      contentRect: NSMakeRect(0, 0, 0, 0), styleMask: .borderless, backing: .buffered,
      defer: false)
  }

  override init(
    contentRect: NSRect, styleMask style: NSWindow.StyleMask,
    backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool
  ) {
    self.backgroundView = NSVisualEffectView()
    self.applicationView = ResizingView(withPadding: mainPadding)
    self.selectionView = NSVisualEffectView()

    super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: false)

    self.isMovableByWindowBackground = true
    self.backgroundColor = .clear
    self.isOpaque = false

    self.collectionBehavior = .moveToActiveSpace

    self.setIsVisible(false)

    self.contentView = ContentView(frame: NSMakeRect(0, 0, 0, 0))

    backgroundView.state = .active
    backgroundView.blendingMode = .behindWindow
    backgroundView.autoresizingMask = [.width, .height]
    backgroundView.wantsLayer = true
    backgroundView.layer!.cornerRadius = 16

    self.contentView!.addSubview(backgroundView)

    selectionView.wantsLayer = true
    selectionView.layer!.cornerRadius = 8
    selectionView.autoresizingMask = [.width, .height]
    selectionView.wantsLayer = true
    selectionView.state = .active
    selectionView.blendingMode = .behindWindow
    selectionView.material = .mediumLight

    self.contentView!.addSubview(selectionView)

    applicationView.wantsLayer = true
    applicationView.layer?.masksToBounds = false
    self.contentView!.addSubview(self.applicationView)

    trackingArea = NSTrackingArea.init(
      rect: self.applicationView.bounds, options: [.activeAlways, .mouseMoved], owner: self,
      userInfo: nil)
    self.contentView!.addTrackingArea(trackingArea!)

    NSWorkspace.shared.notificationCenter.addObserver(
      self, selector: #selector(self.spaceChanged),
      name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
    NSWorkspace.shared.notificationCenter.addObserver(
      self, selector: #selector(self.hideWindow),
      name: NSWorkspace.didHideApplicationNotification, object: nil)
    NSWorkspace.shared.notificationCenter.addObserver(
      self, selector: #selector(self.unhideWindow),
      name: NSWorkspace.didUnhideApplicationNotification, object: nil)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidMove(_:)),
      name: NSWindow.didMoveNotification,
      object: self
    )
  }

  deinit {
    moveStopTimer?.invalidate()
    NotificationCenter.default.removeObserver(self)
    NSWorkspace.shared.notificationCenter.removeObserver(self)
  }

  @objc func windowDidMove(_ notification: Notification) {
    moveStopTimer?.invalidate()

    moveStopTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
      self?.windowDidStopMoving()
    }
  }

  func windowDidStopMoving() {
    let y = NSScreen.main!.frame.height / 2 - self.applicationView.frame.height / 2
    PreferenceStore.shared.previewY = Int(y - self.frame.origin.y)
  }

  override func mouseExited(with event: NSEvent) {
    self.mouseSelection(.zero)
  }

  override func mouseMoved(with event: NSEvent) {
    self.mouseSelection(event.locationInWindow)
  }

  func cycleForwards() {
    self.moveSelection(by: 1)
  }

  func cycleBackwards() {
    self.moveSelection(by: -1)
  }

  func hide(activate: Bool = true) {
    self.setIsVisible(false)
    if activate {
      self.activateCurrent()
    }
  }

  func show() {
    // Get appeareance
    let appearance = NSApp.effectiveAppearance
    NSAppearance.current = appearance

    if appearance.name == .darkAqua || appearance.name == .vibrantDark {
      backgroundView.material = .dark
      selectionView.material = .ultraDark
    } else {
      backgroundView.material = .light
      selectionView.material = .mediumLight
    }

    DispatchQueue.main.async {
      self.reloadApplications()
      self.updateSelectionView()
      self.makeKeyAndOrderFront(nil)
      self.orderFrontRegardless()
    }
    self.setIsVisible(true)
  }

  @objc func spaceChanged() {
    self.windowList = []
    self.selected = 0
    self.hide(activate: false)
  }

  func changeWindowHiddenStatus(_ app: NSRunningApplication, isHidden: Bool) {
    for win in self.windowList {
      if win.app.processIdentifier == app.processIdentifier {
        win.isHidden = isHidden
      }
    }
  }

  @objc func hideWindow(_ notification: NSNotification) {
    let running: NSRunningApplication =
      notification.userInfo![NSWorkspace.applicationUserInfoKey] as! NSRunningApplication
    changeWindowHiddenStatus(running, isHidden: true)
  }

  @objc func unhideWindow(_ notification: NSNotification) {
    let running: NSRunningApplication =
      notification.userInfo![NSWorkspace.applicationUserInfoKey] as! NSRunningApplication
    changeWindowHiddenStatus(running, isHidden: false)
  }

  func activateCurrent() {
    // Clamp selectedIndex to [0, count-1] even for negative self.selected
    let selectedIndex = ((self.selected % windowList.count) + windowList.count) % windowList.count
    let qsWindow = windowList[selectedIndex]
    qsWindow.focus()

    if qsWindow.isClosed {
      NSWorkspace.shared.launchApplication(
        withBundleIdentifier: qsWindow.app.bundleIdentifier!, options: .default,
        additionalEventParamDescriptor: nil, launchIdentifier: nil)
    }

    qsWindow.isClosed = false
    qsWindow.isHidden = false

    windowList.remove(at: selectedIndex)
    windowList.insert(qsWindow, at: 0)

    self.selected = 0
    DispatchQueue.main.async {
      self.updateSelectionView()
      self.updateApplicationViews()
    }
  }

  func mouseSelection(_ point: CGPoint) {
    let mouseSelection: Bool = PreferenceStore.shared.enableMouseSelection
    let selectionPadding = self.cellMargin / 2

    for (i, view) in self.applicationView.subviews.enumerated() {
      let padded = NSRect(
        origin: NSMakePoint(
          CGFloat(view.frame.origin.x - selectionPadding),
          CGFloat(view.frame.origin.y - selectionPadding)),
        size: NSMakeSize(
          view.frame.size.width + selectionPadding * 2,
          view.frame.size.height + selectionPadding * 2))

      if padded.contains(point) {
        if mouseSelection {
          self.moveSelection(toIndex: i)
        }
        break
      }
    }
  }

  func moveSelection(by offset: Int) {
    moveSelection(toIndex: selected + offset)
  }

  func moveSelection(toIndex index: Int) {
    self.selected = index
    self.updateSelectionView()
  }

  func reloadApplications() {
    let applications = NSWorkspace.shared.runningApplications

    let orderedWindowsList = CGWindowListCopyWindowInfo(
      [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)

    var appPIDMap: [pid_t: NSRunningApplication] = [:]
    var axWindowMap: [CGWindowID: AXUIElement] = [:]
    for app: NSRunningApplication in applications {
      if app.activationPolicy != .regular { continue }

      let axApp = AXUIElementCreateApplication(app.processIdentifier)
      let windowPtr = UnsafeMutablePointer<AnyObject?>.allocate(capacity: 1)
      AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, windowPtr)
      let axWindowList = windowPtr.pointee as? [AXUIElement] ?? []
      windowPtr.deallocate()

      appPIDMap[app.processIdentifier] = app
      for axWindow in axWindowList {
        let windowId = getWindowId(axWindow)
        axWindowMap[windowId] = axWindow
      }
    }

    let orderedWindowInfo = CGWindow.createArrayFromList(orderedWindowsList)

    windowList = orderedWindowInfo.filter { (window) -> Bool in
      let app = appPIDMap[window.processIdentifier]
      if app == nil {
        return false
      }

      // Ignore the current application
      if app!.processIdentifier == ProcessInfo.processInfo.processIdentifier {
        // ???
        if window.windowName == "Item-0" {
          return false
        }
      }

      // filter the garbage
      if window.bounds.width < 23 || window.bounds.height < 23 {
        return false
      }

      if window.windowName == "" {
        return false
      }

      return true
    }
    .map { (window) -> QSWindow in
      let axWindowMatch = axWindowMap[window.windowId()]
      let app = appPIDMap[window.processIdentifier]!

      return QSWindow(cgWindow: window, axWindow: axWindowMatch, app: app)
    }

    updateApplicationViews()
  }

  func updateApplicationViews() {
    for subview in applicationView.subviews {
      subview.removeFromSuperview()
    }

    let screenWidth = NSScreen.main!.frame.width

    var xOffset: CGFloat = 0
    let cellSize: CGFloat = CGFloat.init(PreferenceStore.shared.iconSize)
    let breakAfter = Int((screenWidth - 500) / (cellSize + cellMargin))

    for (index, qsWindow) in windowList.enumerated() {
      if index % breakAfter == 0 {
        xOffset = 0
      }

      let row = index / breakAfter
      let maxRow = (windowList.count - 1) / breakAfter
      let yOffset = CGFloat(maxRow - row) * (cellSize + cellMargin)
      let offset = NSMakePoint(xOffset, yOffset)

      let appPreview = NSView(
        frame: NSRect(origin: offset, size: NSMakeSize(cellSize, cellSize)))

      appPreview.wantsLayer = true
      appPreview.layer?.masksToBounds = false
      // appPreview.layer?.backgroundColor = .init(red: 255, green: 0, blue: 0, alpha: 1)

      let nameLabel = NSLabel(text: qsWindow.title())
      nameLabel.preferredMaxLayoutWidth = cellSize
      nameLabel.lineBreakMode = .byTruncatingTail
      nameLabel.font = .systemFont(ofSize: 12, weight: .bold)
      nameLabel.textColor = .textColor.withAlphaComponent(0.75)
      nameLabel.alignment = .left
      nameLabel.setFrameSize(NSMakeSize(cellSize, nameLabel.frame.height))
      nameLabel.setFrameOrigin(NSMakePoint(0, 2))
      appPreview.addSubview(nameLabel)

      let appLabel = NSLabel(text: qsWindow.app.localizedName!)
      appLabel.preferredMaxLayoutWidth = cellSize
      appLabel.lineBreakMode = .byTruncatingTail
      appLabel.font = .systemFont(ofSize: 10, weight: .ultraLight)
      appLabel.textColor = .textColor.withAlphaComponent(0.95)
      appLabel.alignment = .left

      // Set kerning (character spacing)
      let appLabelAttrString = NSMutableAttributedString(string: qsWindow.app.localizedName!)
      appLabelAttrString.addAttribute(
        .kern, value: 0.5, range: NSRange(location: 0, length: appLabelAttrString.length))
      appLabel.attributedStringValue = appLabelAttrString

      appLabel.setFrameOrigin(NSMakePoint(0, nameLabel.frame.height))
      appPreview.addSubview(appLabel)

      let iconY = nameLabel.frame.height + 15
      let iconView = NSImageView(
        frame: NSMakeRect(
          0,
          iconY,
          cellSize,
          cellSize - iconY)
      )
      if qsWindow.isHidden {
        iconView.alphaValue = 0.4
      }

      iconView.image = qsWindow.app.icon!
      iconView.image!.size = NSMakeSize(cellSize / 1.5, cellSize / 1.5)
      appPreview.addSubview(iconView)

      if qsWindow.isClosed {
        appPreview.alphaValue = 0.6
      }
      let shadow = Shadow(0.25, .black, NSMakeSize(0, 0), 12)
      iconView.addShadow(shadow)

      applicationView.addSubview(appPreview)
      xOffset += appPreview.frame.width + cellMargin
    }

    self.applicationView.resize()
    let previewY: CGFloat = CGFloat(PreferenceStore.shared.previewY)

    // Center the application view in the window
    let x = NSScreen.main!.frame.width / 2 - self.applicationView.frame.width / 2
    let y = NSScreen.main!.frame.height / 2 - self.applicationView.frame.height / 2 - previewY
    let newFrame = CGRect(origin: NSMakePoint(x, y), size: self.applicationView.frame.size)
    self.setFrame(newFrame, display: true)

    // Update the tracking area to new frame
    self.contentView?.removeTrackingArea(trackingArea!)
    trackingArea = NSTrackingArea.init(
      rect: self.applicationView.bounds,
      options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited],
      owner: self, userInfo: nil)
    self.contentView?.addTrackingArea(trackingArea!)
  }

  func updateSelectionView() {
    let count = windowList.count
    if count == 0 {
      return
    }
    // Clamp selectedIndex to [0, count-1] even for negative self.selected
    let selectedIndex = ((self.selected % windowList.count) + windowList.count) % windowList.count
    let subview = applicationView.subviews[selectedIndex]

    let selectionPadding = self.cellMargin / 2

    let newSize = NSMakeSize(
      subview.frame.size.width + selectionPadding * 2,
      subview.frame.size.height + selectionPadding * 2)
    let newOrigin = NSMakePoint(
      subview.frame.origin.x - selectionPadding,
      subview.frame.origin.y - selectionPadding)

    let newSelectionFrame = CGRect(origin: newOrigin, size: newSize)

    let bounds = self.backgroundView.bounds
    let newPath = CGMutablePath()
    newPath.addRect(bounds)
    newPath.addRoundedRect(
      in: newSelectionFrame,
      cornerWidth: 10,
      cornerHeight: 10)

    if self.selectionView.frame.origin.x == 0 {
      let firstView = applicationView.subviews[0]
      let firstViewSize = NSMakeSize(
        firstView.frame.size.width + selectionPadding * 2,
        firstView.frame.size.height + selectionPadding * 2)
      let firstViewOrigin = NSMakePoint(
        firstView.frame.origin.x - selectionPadding,
        firstView.frame.origin.y - selectionPadding)
      let firstViewFrame = CGRect(origin: firstViewOrigin, size: firstViewSize)
      self.selectionView.frame = firstViewFrame
    }

    DispatchQueue.main.async {
      NSAnimationContext.runAnimationGroup(
        { context in
          context.duration = 0.1
          context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
          self.selectionView.animator().frame = newSelectionFrame
        }, completionHandler: nil)
    }
  }
}
