import SwiftUI

struct DebouncedTextField: ViewModifier {
  // on change start timeout
  // if you receive a change reset the timeout
  // once timeout passes execute the given function
  // potentially if another change happens before
  // the task is finished cancel the task or ignore the results
  let timeout: Duration
  let task: (String) -> Void
  // @State var taskHandle: Task<Void, Never>?
  @Binding var observedValue: String

  func body(content: Content) -> some View {
    content
      .onChange(of: observedValue) { _, newValue in
        // taskHandle = Task {
        Task {
          try await Task.sleep(for: timeout)
          if newValue != observedValue {
            return
          }

          task(newValue)
        }
      }
  }
}

extension View {
  func debouncedTextField(
    timeout: Duration = .milliseconds(250),
    observedValue: Binding<String>,
    task: @escaping (String) -> Void,
  ) -> some View {
    modifier(DebouncedTextField(timeout: timeout, task: task, observedValue: observedValue))
  }
}
