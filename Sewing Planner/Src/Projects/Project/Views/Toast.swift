//
//  Toast.swift
//  Sewing Planner
//
//  Created by Art on 11/11/24.
//

import SwiftUI

struct Toast: View {
  @Binding var showToast: ProjectError?

  var body: some View {
    if let error = showToast {
      let message =
        switch error {
          case .addSection:
            "Couldn't add a new section."
          case .addSectionItem:
            "Couldn't add an item to the section."
          case .deleteImages:
            "Couldn't delete images."
          case .deleteSection:
            "Couldn't delete the section."
          case .deleteSectionItems:
            "Couldn't delete selected items."
          case .importImage:
            "Couldn't save imported image."
          case .loadImages:
            "Couldn't load project images."
          case .reOrderSectionItems:
            "Couldn't reorder section items."
          case .renameProject:
            "Couldn't rename project."
          case .updateSectionItemText:
            "Couldn't update item text."
          case .updateSectionItemCompletion:
            "Couldn't update item completion."
          default:
            "Something went wrong. Please try again."
        }

      HStack {
        Text(message)
          .font(.custom("SourceSans3-Regular", size: 16))
          .foregroundStyle(.white)
          .padding([.horizontal, .vertical], 10)
          .frame(maxWidth: .infinity, alignment: .leading)
        Button {
          showToast = nil
        } label: {
          Image(systemName: "xmark")
            .foregroundStyle(.white)
            .padding(10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, 20)
      }
      .padding([.trailing], 10)
      .background(
        RoundedRectangle(cornerRadius: 9)
          .fill(
            // TODO: look into more gradients to create pastel/glassy look
            LinearGradient(
              colors: [Color(hex: 0xE62020, opacity: 1), Color(hex: 0xF40009, opacity: 1)],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .shadow(radius: 3, x: 0, y: 4)
      )
      .frame(minWidth: 200, maxWidth: 400, minHeight: 75, maxHeight: 120)
      .onAppear {
        Task { @MainActor in
          try await Task.sleep(for: .seconds(10))
          showToast = nil
        }
      }
    }
  }
}

#Preview {
  @Previewable @State var showToast: ProjectError? = nil
  var _ = "This is some text to demonstrate how the toast will look with long text"

  VStack {
    Button("Toggle Toast") {
      showToast = .addSection
    }
    Toast(showToast: $showToast)
  }
  .frame(width: 500, height: 500)
  .background(.white)
}
