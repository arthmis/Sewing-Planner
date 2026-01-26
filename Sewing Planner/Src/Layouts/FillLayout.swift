import SwiftUI

/// A custom layout that uses all available space and gives it entirely to its child view.
/// Ideal for images or other content that should fill their container.
///
/// Usage:
/// ```
/// FillLayout {
///     Image("myImage")
///         .resizable()
/// }
/// ```
struct FillLayout: Layout {

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    // Return the full proposed size, using zero as fallback for nil dimensions
    CGSize(
      width: proposal.width ?? 0,
      height: proposal.height ?? 0
    )
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    precondition(subviews.count == 1)
    // Place each subview to fill the entire bounds
    for subview in subviews {
      let subviewSize = subview.sizeThatFits(ProposedViewSize(bounds.size))
      let x = bounds.midX - subviewSize.width / 2
      let y = bounds.midY - subviewSize.height / 2
      subview.place(
        at: CGPoint(x: x, y: y),
        proposal: ProposedViewSize(bounds.size)
      )
    }
  }
}

// MARK: - Convenience View Extension

extension View {
  /// Wraps the view in a FillLayout to make it use all available space.
  func fill() -> some View {
    FillLayout {
      self
    }
  }
}

// MARK: - Preview

#Preview {
  FillLayout {
    Image(systemName: "photo")
      .resizable()
      .aspectRatio(contentMode: .fill)
  }
  .frame(width: 200, height: 300)
  .clipped()
  .border(Color.red)
}
