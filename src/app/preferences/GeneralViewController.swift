//
//  GeneralViewController.swift
//  vechseler
//
//  Created by Björn Friedrichs on 27/04/2019.
//  Copyright © 2019 Björn Friedrichs. All rights reserved.
//

import Cocoa

class PointingHandLabel: NSLabel {
  override func resetCursorRects() {
    self.addCursorRect(self.bounds, cursor: .pointingHand)
  }
}

class GeneralViewController: NSViewController, PreferencePane {
  var preferenceTabTitle = "General"

  class FlippedView: NSView {
    override var isFlipped: Bool { true }
  }

  override func loadView() {
    // Container view to ensure edgeInsets are respected
    let container = NSView()
    container.translatesAutoresizingMaskIntoConstraints = false

    // Card-like container for the whole preferences pane
    let mainStack = NSStackView()
    mainStack.orientation = .vertical
    mainStack.spacing = 16
    mainStack.alignment = .leading
    mainStack.translatesAutoresizingMaskIntoConstraints = false
    mainStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true

    // Info label with pointing hand cursor
    let infoLabel = NSLabel(
      text: "Vechsel is in active development. Please report any issues you find on GitHub."
    )
    infoLabel.lineBreakMode = .byWordWrapping
    infoLabel.maximumNumberOfLines = 3
    infoLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
    infoLabel.textColor = .secondaryLabelColor
    infoLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
    infoLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    infoLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    infoLabel.widthAnchor.constraint(
      lessThanOrEqualToConstant: 400
    ).isActive = true  // Limit width for better readability

    mainStack.addArrangedSubview(infoLabel)

    // GitHub link with pointing hand cursor
    let githubLabel = PointingHandLabel(text: "View on GitHub")
    githubLabel.isSelectable = true
    githubLabel.isEditable = false
    githubLabel.isBezeled = false
    githubLabel.drawsBackground = false
    githubLabel.textColor = NSColor.linkColor
    githubLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
    githubLabel.allowsEditingTextAttributes = true
    let url = "https://github.com/itsbjoern/vechsel"
    let attributedString = NSMutableAttributedString(string: "View on GitHub")
    attributedString.beginEditing()
    attributedString.addAttribute(
      .link, value: url, range: NSRange(location: 0, length: attributedString.length))
    attributedString.endEditing()
    githubLabel.attributedStringValue = attributedString
    mainStack.addArrangedSubview(githubLabel)

    mainStack.addArrangedSubview(makeSectionHeader(title: "Application Settings"))
    let openAtLoginCheckbox = NSButton(
      checkboxWithTitle: "Open at Login", target: self, action: #selector(openAtLoginToggled(_:)))
    openAtLoginCheckbox.state = PreferenceStore.shared.openAtLogin ? .on : .off
    openAtLoginCheckbox.setContentHuggingPriority(.defaultHigh, for: .vertical)
    mainStack.addArrangedSubview(openAtLoginCheckbox)

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

    // Ensure mainStack is inset by 20pt from the container on all sides
    NSLayoutConstraint.activate([
      mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
      mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
      mainStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
      mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
    ])
  }

  @objc func resetPreview(_ button: NSButton) {
    PreferenceStore.shared.previewY = 0
  }

  @objc func doneButtonPressed(_ sender: NSButton) {
    self.view.window?.close()
  }

  @objc func quitButtonPressed(_ sender: NSButton) {
    NSApplication.shared.terminate(nil)
  }

  @objc func openAtLoginToggled(_ sender: NSButton) {
    PreferenceStore.shared.openAtLogin = (sender.state == .on)
  }
}
