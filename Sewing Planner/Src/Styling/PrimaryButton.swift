//
//  PrimaryButton.swift
//  Sewing Planner
//
//  Created by Art on 9/23/24.
//

import SwiftUI

struct SectionViewButton<Content: View>: View {
  @State var isHovering = false
  let action: @MainActor () -> Void
  @ViewBuilder let label: () -> Content

  var body: some View {
    Button(action: action, label: label)
      .buttonStyle(SectionTertiaryButtonStyle())
      .scaleEffect(isHovering ? 1.15 : 1, anchor: .center)
      .onHover { hover in
        isHovering = hover
      }
      .animation(.easeIn(duration: 0.13), value: isHovering)
  }
}

// gist for this idea
// https://gist.github.com/arthmis/d3bde814fd0aced3adcef17df3da840a
struct PressedAction: ViewModifier {
  var onPress: () -> Void
  var onRelease: () -> Void

  func body(content: Content) -> some View {
    content.simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in
          onPress()
        }
        .onEnded { _ in
          onRelease()
        }
    )
  }
}

extension View {
  func onPress(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
    modifier(
      PressedAction {
        onPress()
      } onRelease: {
        onRelease()
      }
    )
  }
}

struct ImageButton: View {
  @State var isHovering = false
  let image: ProjectImage
  @Binding var selectedImage: OverlayedImage?
  @State var isPressed = false

  var body: some View {
    if let projectImage = image.image {
      Image(uiImage: projectImage)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(minWidth: 100, maxWidth: .infinity, minHeight: 200, alignment: .center)
        .clipped()
        .scaleEffect(isPressed ? 0.925 : 1)
        .animation(.easeOut(duration: 0.12), value: isPressed)
        // .background(Color(hex: 0xDDDDDD, opacity: isPressed ? 1 : 0))
        // parts of the image that were clipped still respond to the mouse events so this constrains it to the correct area
        .contentShape(Rectangle())
        .onTapGesture {
          selectedImage = OverlayedImage(body: image.path)
        }
        .onPress {
          isPressed = true
        } onRelease: {
          isPressed = false
        }
    } else {
      ProgressView()
        .frame(minWidth: 100, maxWidth: .infinity, minHeight: 200, alignment: .center)
        .clipped()
    }
  }
}

struct SelectedImageButton: View {
  @State var isHovering = false
  @Binding var image: ProjectImage
  @Binding var selectedImagesForDeletion: Set<String?>
  @State var isPressed = false

  var isSelectedForDeletion: Bool {
    selectedImagesForDeletion.contains(image.path)
  }

  var body: some View {
    if let projectImage = image.image {
      Image(uiImage: projectImage)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(minWidth: 100, maxWidth: .infinity, minHeight: 200, alignment: .center)
        .clipped()
        .animation(.easeOut(duration: 0.08), value: isPressed)
        .background(Color(hex: 0xDDDDDD, opacity: isPressed ? 1 : 0))
        // parts of the image that were clipped still respond to the mouse events so this constrains it to the correct area
        .contentShape(Rectangle())
        .overlay(alignment: .center) {
          if isSelectedForDeletion {
            Rectangle()
              .foregroundStyle(Color.gray.opacity(0.4))
          }
        }
        .overlay(alignment: .bottomTrailing) {
          if isSelectedForDeletion {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 24))
              .foregroundStyle(.white, .white, .blue)
              .frame(width: 28, height: 28)
              .background(Color.white)
              .clipShape(Circle())
              .padding([.bottom, .trailing], 16)
          }
        }
        .onTapGesture {
          if !isSelectedForDeletion {
            selectedImagesForDeletion.insert(image.path)
          } else {
            selectedImagesForDeletion.remove(image.path)
          }
        }
        .onPress {
          isPressed = true
        } onRelease: {
          isPressed = false
        }
    } else {
      ProgressView()
        .frame(minWidth: 100, maxWidth: .infinity, minHeight: 200, alignment: .center)
        .clipped()
    }
  }
}

#Preview {
  SectionViewButton {
  } label: {
    Image(systemName: "ellipsis")
  }
}
