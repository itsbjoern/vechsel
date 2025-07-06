//
//  ConfigViewController.swift
//  vechseler
//
//  Created by Björn Friedrichs on 04/05/2019.
//  Copyright © 2019 Björn Friedrichs. All rights reserved.
//

import Cocoa

class SequenceButton: NSButton {
  var shortcutTitle: String?

  func setRecording() {
    self.isEnabled = false
    self.shortcutTitle = self.title
    self.title = "● Recording"
    self.sizeToFit()
    self.needsDisplay = true
  }

  func setNormal() {
    self.isEnabled = true
    self.title = self.shortcutTitle!
    self.sizeToFit()
    self.needsDisplay = true
  }
}

class ConfigViewController: NSViewController, PreferencePane {
  var preferenceTabTitle = "Config"

  // Buttons need to be properties so they can be updated
  let mainSequenceButton = SequenceButton(title: "", target: nil, action: nil)
  let reverseSequenceButton = SequenceButton(title: "", target: nil, action: nil)
  var recordingButton: SequenceButton?

  // --- Begin Icon Size and Switcher Position (moved from General) ---
  struct PreviewBoxSpec {
    let size: CGFloat
    let label: String
    let color = NSColor.systemBlue
  }

  let previewSizes = [
    PreviewBoxSpec(size: 75, label: "Small"),
    PreviewBoxSpec(size: 100, label: "Medium"),
    PreviewBoxSpec(size: 125, label: "Large"),
  ]
  var previewBoxes: [NSBox] = []

  override func loadView() {
    print("Loading ConfigViewController")
    // Container view for padding
    let container = NSView()
    container.translatesAutoresizingMaskIntoConstraints = false

    // Main vertical stack
    let mainStack = NSStackView()
    mainStack.orientation = .vertical
    mainStack.spacing = 16
    mainStack.alignment = .leading
    mainStack.translatesAutoresizingMaskIntoConstraints = false

    // Section: Keys
    mainStack.addArrangedSubview(makeSectionHeader(title: "Keys"))

    // Cycle Forwards
    let mainSeqStack = NSStackView()
    mainSeqStack.orientation = .horizontal
    mainSeqStack.spacing = 8
    mainSeqStack.alignment = .centerY

    let mainSeqLabel = NSLabel(text: "Cycle Forwards")
    mainSeqLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
    mainSeqLabel.textColor = .labelColor
    mainSeqLabel.toolTip = "Key sequence used to activate and cycle forwards."

    let mainSequence = PreferenceStore.shared.mainSequence
    mainSequenceButton.title = sequenceToString(mainSequence)
    mainSequenceButton.sizeToFit()
    mainSequenceButton.needsDisplay = true
    mainSequenceButton.setFrameX(-5)
    mainSequenceButton.target = self
    mainSequenceButton.action = #selector(mainSequenceChange(_:))

    mainSeqStack.addArrangedSubview(mainSeqLabel)
    mainSeqStack.addArrangedSubview(mainSequenceButton)
    mainStack.addArrangedSubview(mainSeqStack)

    // Cycle Backwards
    let reverseSeqStack = NSStackView()
    reverseSeqStack.orientation = .horizontal
    reverseSeqStack.spacing = 8
    reverseSeqStack.alignment = .centerY

    let reverseSeqLabel = NSLabel(text: "Cycle Backwards")
    reverseSeqLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
    reverseSeqLabel.textColor = .labelColor
    reverseSeqLabel.toolTip = "Key sequence used to activate and cycle backwards."

    let reverseSequence = PreferenceStore.shared.reverseSequence
    reverseSequenceButton.title = sequenceToString(reverseSequence)
    reverseSequenceButton.sizeToFit()
    reverseSequenceButton.needsDisplay = true
    reverseSequenceButton.setFrameX(-5)
    reverseSequenceButton.target = self
    reverseSequenceButton.action = #selector(reverseSequenceChange(_:))

    let shiftCheckbox = NSButton(
      checkboxWithTitle: "Enable backwards cycling with ⌘ + ⇧ while activated.", target: self,
      action: #selector(setCycleShift(_:)))
    shiftCheckbox.state = PreferenceStore.shared.cycleBackwardsWithShift ? .on : .off

    let reverseButtonStack = NSStackView()
    reverseButtonStack.orientation = .vertical
    reverseButtonStack.spacing = 6
    reverseButtonStack.alignment = .leading
    reverseButtonStack.addArrangedSubview(reverseSequenceButton)
    reverseButtonStack.addArrangedSubview(shiftCheckbox)

    reverseSeqStack.addArrangedSubview(reverseSeqLabel)
    reverseSeqStack.addArrangedSubview(reverseButtonStack)
    mainStack.addArrangedSubview(reverseSeqStack)

    mainStack.addArrangedSubview(makeSectionHeader(title: "Icon Size"))

    let sizeStack = NSStackView(
      views: self.previewSizes.map { box in
        makePreviewBox(spec: box)
      })
    sizeStack.orientation = .horizontal
    sizeStack.spacing = 8
    sizeStack.alignment = .top
    sizeStack.distribution = .equalSpacing
    mainStack.addArrangedSubview(sizeStack)
    highlightSelectedPreviewBox(selectedSize: PreferenceStore.shared.iconSize)

    mainStack.addArrangedSubview(makeSectionHeader(title: "Switcher Position"))
    let explainerLabel = NSLabel(
      text:
        "You can move the position of the switcher preview by dragging it while it is active. Click the button below to reset it back to the center of the screen."
    )
    explainerLabel.lineBreakMode = .byWordWrapping
    explainerLabel.maximumNumberOfLines = 0
    explainerLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
    explainerLabel.textColor = .secondaryLabelColor
    explainerLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
    explainerLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    explainerLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    explainerLabel.widthAnchor.constraint(
      lessThanOrEqualToConstant: 400
    ).isActive = true  // Limit width for better readability
    mainStack.addArrangedSubview(explainerLabel)

    // Reset preview position
    let resetStack = NSStackView()
    resetStack.orientation = .horizontal
    resetStack.spacing = 12
    resetStack.alignment = .centerY
    let resetLabel = NSLabel(text: "Reset Position")
    resetLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
    resetLabel.textColor = .labelColor
    resetStack.addArrangedSubview(resetLabel)

    let resetPreviewButton = NSButton(
      title: "", target: self, action: #selector(resetPreview(_:)))
    resetPreviewButton.title = "Reset"
    resetPreviewButton.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
    resetPreviewButton.bezelStyle = .rounded
    resetPreviewButton.contentTintColor = .controlAccentColor
    resetPreviewButton.sizeToFit()
    resetPreviewButton.needsDisplay = true
    resetPreviewButton.setFrameX(-5)
    resetStack.addArrangedSubview(resetPreviewButton)

    mainStack.addArrangedSubview(resetStack)

    // Section: Other
    mainStack.addArrangedSubview(makeSectionHeader(title: "Other"))

    // Enable mouse selection
    let mouseStack = NSStackView()
    mouseStack.orientation = .horizontal
    mouseStack.spacing = 8
    mouseStack.alignment = .centerY

    let mouseLabel = NSLabel(text: "Enable mouse selection")
    mouseLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
    mouseLabel.textColor = .labelColor
    mouseLabel.toolTip = "Select windows by hovering with the mouse"

    let mouseCheckbox = NSButton(
      checkboxWithTitle: "", target: self, action: #selector(setEnableMouseSelection(_:)))
    mouseCheckbox.state = PreferenceStore.shared.enableMouseSelection ? .on : .off

    mouseStack.addArrangedSubview(mouseLabel)
    mouseStack.addArrangedSubview(mouseCheckbox)
    mainStack.addArrangedSubview(mouseStack)

    // Add Done and Quit Vechsel buttons
    let buttonStack = NSStackView()
    buttonStack.orientation = .horizontal
    buttonStack.spacing = 12
    buttonStack.alignment = .centerY

    let doneButton = NSButton(title: "Done", target: self, action: #selector(doneButtonPressed))
    doneButton.bezelStyle = .rounded
    doneButton.font = NSFont.systemFont(ofSize: 13, weight: .regular)
    buttonStack.addArrangedSubview(doneButton)

    let quitButton = NSButton(
      title: "Quit Vechsel", target: self, action: #selector(quitButtonPressed))
    quitButton.bezelStyle = .rounded
    quitButton.font = NSFont.systemFont(ofSize: 13, weight: .regular)
    buttonStack.addArrangedSubview(quitButton)

    mainStack.addArrangedSubview(buttonStack)

    container.addSubview(mainStack)
    self.view = container

    // Padding: 20pt on all sides
    NSLayoutConstraint.activate([
      mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
      mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
      mainStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
      mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
    ])
  }

  func sequenceToString(_ sequence: [Int64]) -> String {
    var out = ""
    for key in sequence {
      if KeyHandler.FlagAsInt.contains(key: key) {
        out += " + \(KeyHandler.FlagAsInt(rawValue: key)!.asString())"
      } else {
        out += " + \(KeyCodes[key, default: KeyCode("?", 99999)].key)"
      }
    }
    return " \(String(out.dropFirst(3))) "
  }

  @objc func mainSequenceChange(_ button: SequenceButton) {
    let delegate = NSApplication.shared.delegate as! AppDelegate
    let keyHandler = delegate.keyHandler
    recordingButton = button

    button.setRecording()

    keyHandler!.recordSequence { (sequence) in
      button.setNormal()
      PreferenceStore.shared.mainSequence = sequence
      button.title = self.sequenceToString(sequence)
      button.sizeToFit()
      self.recordingButton = nil
    }
  }

  @objc func reverseSequenceChange(_ button: SequenceButton) {
    let delegate = NSApplication.shared.delegate as! AppDelegate
    let keyHandler = delegate.keyHandler
    recordingButton = button

    button.setRecording()

    keyHandler!.recordSequence { (sequence) in
      button.setNormal()
      PreferenceStore.shared.reverseSequence = sequence
      button.title = self.sequenceToString(sequence)
      button.sizeToFit()
      self.recordingButton = nil
    }
  }

  func paneWillDisappear() {
    let delegate = NSApplication.shared.delegate as! AppDelegate
    let keyHandler = delegate.keyHandler
    keyHandler!.stopRecording()

    guard let button = recordingButton else {
      return
    }
    button.setNormal()
  }

  @objc func setCycleShift(_ checkbox: NSButton) {
    let isOn = checkbox.state == .on
    PreferenceStore.shared.cycleBackwardsWithShift = isOn
  }

  @objc func setEnableMouseSelection(_ checkbox: NSButton) {
    let isOn = checkbox.state == .on
    PreferenceStore.shared.enableMouseSelection = isOn
  }

  // Preview size boxes
  func makePreviewBox(spec: PreviewBoxSpec) -> NSStackView {
    // Outer wrapper for alignment and background
    let wrapper = NSBox()
    wrapper.boxType = .custom
    wrapper.cornerRadius = 18
    wrapper.fillColor = spec.color.withAlphaComponent(0.09)
    wrapper.translatesAutoresizingMaskIntoConstraints = false
    wrapper.widthAnchor.constraint(equalToConstant: self.previewSizes.last!.size + 30).isActive =
      true
    wrapper.wantsLayer = true
    wrapper.layer?.borderWidth = 1
    wrapper.layer?.borderColor = spec.color.withAlphaComponent(0.18).cgColor
    wrapper.layer?.cornerRadius = 18
    wrapper.animator()
    self.previewBoxes.append(wrapper)
    let clickGesture = NSClickGestureRecognizer(
      target: self, action: #selector(self.previewBoxClicked(_:)))
    wrapper.identifier = NSUserInterfaceItemIdentifier("\(Int(spec.size))")
    wrapper.addGestureRecognizer(clickGesture)
    let innerStack = NSStackView()
    innerStack.orientation = .vertical
    innerStack.alignment = .centerX
    innerStack.spacing = 16
    innerStack.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    innerStack.translatesAutoresizingMaskIntoConstraints = false
    let boxOuter = NSBox()
    boxOuter.boxType = .custom
    boxOuter.fillColor = .clear
    boxOuter.borderColor = .clear
    boxOuter.widthAnchor.constraint(equalToConstant: self.previewSizes.last!.size).isActive = true
    boxOuter.heightAnchor.constraint(equalToConstant: self.previewSizes.last!.size).isActive = true
    let box = NSBox()
    box.boxType = .custom
    box.cornerRadius = 14
    box.fillColor = spec.color.withAlphaComponent(0.18)
    box.borderColor = .clear
    box.translatesAutoresizingMaskIntoConstraints = false
    boxOuter.addSubview(box)
    box.widthAnchor.constraint(equalToConstant: spec.size).isActive = true
    box.heightAnchor.constraint(equalToConstant: spec.size).isActive = true
    box.centerXAnchor.constraint(equalTo: boxOuter.centerXAnchor).isActive = true
    box.centerYAnchor.constraint(equalTo: boxOuter.centerYAnchor).isActive = true
    box.wantsLayer = true
    box.layer?.cornerRadius = 14
    box.layer?.backgroundColor = spec.color.withAlphaComponent(0.10).cgColor
    let textLabel = NSLabel(text: spec.label)
    textLabel.alignment = .center
    textLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
    textLabel.textColor = .secondaryLabelColor
    let pxLabel = NSLabel(text: "\(Int(spec.size)) px")
    pxLabel.alignment = .center
    pxLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
    pxLabel.textColor = .tertiaryLabelColor
    let labelStack = NSStackView(views: [textLabel, pxLabel])
    labelStack.orientation = .vertical
    labelStack.alignment = .centerX
    labelStack.spacing = 1
    innerStack.addArrangedSubview(boxOuter)
    innerStack.addArrangedSubview(labelStack)
    wrapper.contentView?.addSubview(innerStack)
    NSLayoutConstraint.activate([
      innerStack.centerXAnchor.constraint(equalTo: wrapper.contentView!.centerXAnchor),
      innerStack.centerYAnchor.constraint(equalTo: wrapper.contentView!.centerYAnchor),
      innerStack.leadingAnchor.constraint(
        greaterThanOrEqualTo: wrapper.contentView!.leadingAnchor, constant: 0),
      innerStack.trailingAnchor.constraint(
        lessThanOrEqualTo: wrapper.contentView!.trailingAnchor, constant: 0),
      innerStack.topAnchor.constraint(
        greaterThanOrEqualTo: wrapper.contentView!.topAnchor, constant: 0),
      innerStack.bottomAnchor.constraint(
        lessThanOrEqualTo: wrapper.contentView!.bottomAnchor, constant: 0),
    ])
    let stack = NSStackView(views: [wrapper])
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 0
    return stack
  }

  func highlightSelectedPreviewBox(selectedSize: Int) {
    for box in self.previewBoxes {
      if let id = box.identifier?.rawValue, Int(id) == selectedSize {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.18
          box.layer?.borderColor = NSColor.controlAccentColor.cgColor
          box.layer?.shadowColor = NSColor.controlAccentColor.withAlphaComponent(0.18).cgColor
          box.layer?.shadowOpacity = 1
          box.layer?.shadowRadius = 8
          box.layer?.shadowOffset = CGSize(width: 0, height: 2)
        }
      } else {
        NSAnimationContext.runAnimationGroup { context in
          context.duration = 0.18
          box.layer?.borderColor = NSColor.clear.cgColor
          box.layer?.shadowOpacity = 0
        }
      }
    }
  }

  @objc func previewBoxClicked(_ gesture: NSClickGestureRecognizer) {
    guard let box = gesture.view as? NSBox,
      let id = box.identifier?.rawValue,
      let size = Int(id)
    else { return }
    PreferenceStore.shared.iconSize = size
    highlightSelectedPreviewBox(selectedSize: size)
  }

  @objc func resetPreview(_ button: NSButton) {
    PreferenceStore.shared.previewY = 0
  }
  // --- End Icon Size and Switcher Position ---

  @objc func doneButtonPressed(_ sender: NSButton) {
    self.view.window?.close()
  }

  @objc func quitButtonPressed(_ sender: NSButton) {
    NSApplication.shared.terminate(nil)
  }
}
