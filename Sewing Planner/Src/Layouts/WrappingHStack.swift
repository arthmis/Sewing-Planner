import SwiftUI

/// A custom layout that arranges views horizontally like an HStack,
/// but wraps items to the next line when they don't fit.
/// Designed for use with Text views or Buttons with text labels.
struct WrappingHStack: Layout {
  /// Horizontal spacing between items
  var horizontalSpacing: CGFloat = 8

  /// Vertical spacing between rows
  var verticalSpacing: CGFloat = 8

  /// Alignment for items within each row
  var alignment: VerticalAlignment = .center

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let result = arrangeSubviews(proposal: proposal, subviews: subviews)
    return result.totalSize
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    let arrangement = arrangeSubviews(proposal: proposal, subviews: subviews)

    for (index, subview) in subviews.enumerated() {
      let position = arrangement.positions[index]
      subview.place(
        at: CGPoint(
          x: bounds.minX + position.x,
          y: bounds.minY + position.y
        ),
        proposal: ProposedViewSize(arrangement.sizes[index])
      )
    }
  }

  private struct ArrangementResult {
    var positions: [CGPoint]
    var sizes: [CGSize]
    var totalSize: CGSize
  }

  private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> ArrangementResult
  {
    let maxWidth = proposal.width ?? .infinity

    var positions: [CGPoint] = []
    var sizes: [CGSize] = []

    var currentX: CGFloat = 0
    var currentY: CGFloat = 0
    var rowHeight: CGFloat = 0
    var maxRowWidth: CGFloat = 0

    // First pass: calculate sizes and positions
    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      sizes.append(size)

      // Check if we need to wrap to next line
      if currentX + size.width > maxWidth && currentX > 0 {
        // Move to next row
        currentX = 0
        currentY += rowHeight + verticalSpacing
        rowHeight = 0
      }

      positions.append(CGPoint(x: currentX, y: currentY))

      currentX += size.width + horizontalSpacing
      rowHeight = max(rowHeight, size.height)
      maxRowWidth = max(maxRowWidth, currentX - horizontalSpacing)
    }

    // Apply vertical alignment within rows
    let alignedPositions = applyVerticalAlignment(
      positions: positions,
      sizes: sizes,
      maxWidth: maxWidth
    )

    let totalHeight = currentY + rowHeight
    let totalWidth = min(maxRowWidth, maxWidth)

    return ArrangementResult(
      positions: alignedPositions,
      sizes: sizes,
      totalSize: CGSize(width: totalWidth, height: totalHeight)
    )
  }

  private func applyVerticalAlignment(
    positions: [CGPoint],
    sizes: [CGSize],
    maxWidth: CGFloat
  ) -> [CGPoint] {
    if positions.isEmpty { return positions }

    var alignedPositions = positions

    // Group items by row (same Y position)
    var rowIndices: [[Int]] = []
    var currentRowY: CGFloat = -1
    var currentRowIndices: [Int] = []

    for (index, position) in positions.enumerated() {
      if position.y != currentRowY {
        if !currentRowIndices.isEmpty {
          rowIndices.append(currentRowIndices)
        }
        currentRowIndices = [index]
        currentRowY = position.y
      } else {
        currentRowIndices.append(index)
      }
    }
    if !currentRowIndices.isEmpty {
      rowIndices.append(currentRowIndices)
    }

    // Apply alignment to each row
    for row in rowIndices {
      let rowHeight = row.map { sizes[$0].height }.max() ?? 0

      for index in row {
        let itemHeight = sizes[index].height
        let offset: CGFloat

        switch alignment {
          case .top:
            offset = 0
          case .bottom:
            offset = rowHeight - itemHeight
          default:  // center
            offset = (rowHeight - itemHeight) / 2
        }

        alignedPositions[index].y += offset
      }
    }

    return alignedPositions
  }
}

// MARK: - Preview

#Preview("WrappingHStack Demo") {
  VStack(alignment: .leading, spacing: 20) {
    Text("Button Items:")
      .font(.subheadline)

    WrappingHStack(horizontalSpacing: 8, verticalSpacing: 8) {
      ForEach(["Abaca", "Bamboo", "Cashmere", "Denim", "Elastane", "this is really long text", "Fleece"], id: \.self) { fiber in
        Button {
          print("Selected: \(fiber)")
        } label: {
          HStack {
            Text(fiber)
            Image(systemName: "xmark")
          }
        }
        .buttonStyle(.bordered)
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(8)

    Spacer()
  }
  .padding()
}
