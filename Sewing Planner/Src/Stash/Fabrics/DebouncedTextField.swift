import SwiftUI

struct DebounceView: ViewModifier {
  @State private var debounceTask: Task<Void, Never>? = nil
  let timeout: Duration
  let runTask: () -> Void
  let observedValue: String

  func body(content: Content) -> some View {
    content
      .onChange(of: observedValue) { _, _ in
        debounceTask?.cancel()
        debounceTask = Task {
          try? await Task.sleep(for: timeout)
          if Task.isCancelled {
            return
          }

          runTask()
        }
      }
  }
}

extension View {
  func debounce(
    timeout: Duration = .milliseconds(250),
    observedValue: String,
    task: @escaping () -> Void,
  ) -> some View {
    modifier(DebounceView(timeout: timeout, runTask: task, observedValue: observedValue))
  }
}
