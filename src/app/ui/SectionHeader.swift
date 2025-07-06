import Cocoa

// Creates a section header with a centered label flanked by lines
func makeSectionHeader(title: String) -> NSStackView {
  let stack = NSStackView()
  stack.orientation = .horizontal
  stack.spacing = 12
  stack.alignment = .centerY
  stack.distribution = .fill

  func makeLine() -> NSBox {
    let line = NSBox()
    line.boxType = .custom
    line.borderColor = .quaternaryLabelColor
    line.borderWidth = 0
    line.fillColor = .quaternaryLabelColor
    line.cornerRadius = 1
    line.translatesAutoresizingMaskIntoConstraints = false
    line.heightAnchor.constraint(equalToConstant: 2).isActive = true
    line.setContentHuggingPriority(.defaultLow, for: .horizontal)
    line.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    return line
  }

  let leftLine = makeLine()
  let rightLine = makeLine()

  let label = NSLabel(text: title)
  label.font = NSFont.systemFont(ofSize: 13, weight: .bold)
  label.textColor = .labelColor
  label.alignment = .center
  label.setContentHuggingPriority(.required, for: .horizontal)
  label.setContentCompressionResistancePriority(.required, for: .horizontal)

  stack.addArrangedSubview(leftLine)
  stack.addArrangedSubview(label)
  stack.addArrangedSubview(rightLine)

  // Activate equal width constraint after adding to stack (common ancestor)
  leftLine.widthAnchor.constraint(equalTo: rightLine.widthAnchor).isActive = true

  return stack
}
