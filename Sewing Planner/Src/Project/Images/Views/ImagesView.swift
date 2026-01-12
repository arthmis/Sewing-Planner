//
//  ImagesView.swift
//  Sewing Planner
//
//  Created by Art on 9/12/24.
//

import GRDB
import PhotosUI
import SwiftUI

struct ImagesView: View {
  @Environment(\.db) private var db
  @Environment(ProjectViewModel.self) private var project
  @Binding var model: ProjectImages
  @State var showDeleteImagesDialog = false
  @Namespace var transitionNamespace

  var body: some View {
    VStack(alignment: .center) {
      HStack {
        if model.inDeleteMode {
          InlineImagesDeleteDialogView(
            deleteDisabled: model.selectedImagesIsEmpty,
            showDeleteImagesDialog: $showDeleteImagesDialog
          )
        }
      }
      .frame(maxWidth: .infinity)

      if model.images.isEmpty {
        EmptyProjectImagesCallToActionView()
      } else {
        ScrollView {
          LazyVGrid(
            columns: [
              GridItem(.flexible(minimum: 100, maximum: 400), spacing: 4),
              GridItem(.flexible(minimum: 100, maximum: 400), spacing: 4),
              //                    GridItem(.adaptive(minimum: 100), spacing: 4),
            ],
            spacing: 4
          ) {
            ForEach($model.images, id: \.self.path) { $image in
              if !model.inDeleteMode {
                ImageButton(image: image, selectedImage: $model.overlayedImage)
                  .onLongPressGesture {
                    project.send(
                      event: .ShowDeleteImagesView(initialSelectedImageId: image.record.id),
                      db: db
                    )
                  }
                  .matchedTransitionSource(id: image.path, in: transitionNamespace)
              } else {
                SelectedImageButton(
                  image: $image,
                  selectedImagesForDeletion: $model.selectedImages
                )
              }
            }
          }
        }
      }
    }
    .padding([.horizontal, .bottom], 8)
    .confirmationDialog(
      "Delete Images",
      isPresented: $showDeleteImagesDialog
    ) {
      Button("Delete", role: .destructive) {
        project.send(event: .DeleteImages, db: db)
      }
      Button("Cancel", role: .cancel) {
        showDeleteImagesDialog = false
      }
    } message: {
      if model.selectedImages.count > 1 {
        Text("Delete \(model.selectedImages.count) Images")
      } else {
        Text("Delete Image")
      }
    }
    .sheet(item: $model.overlayedImage) { item in
      ImageOverlayView(
        model: $model,
        item: item,
        transitionNameSpace: transitionNamespace
      )
    }
    .animation(.easeOut(duration: 0.1), value: model.inDeleteMode)
    .animation(.easeOut(duration: 0.1), value: model.overlayedImage)
    .task {
      do {
        try await model.loadProjectImages(db: db)
      } catch {
        project.handleError(error: .loadImages)
      }
    }
  }
}

struct EmptyProjectImagesCallToActionView: View {
  @Environment(ProjectViewModel.self) var project
  @Environment(\.db) var db

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Image(systemName: "photo.on.rectangle.angled")
        .font(.system(size: 32, weight: .light))
      Text("Photos")
        .font(.system(size: 20, weight: .semibold))
        .padding(.top, 20)

      Text(
        "Import photos for references and inspiration. You can share photos from the photos app or web directly to your projects."
      )
      .frame(maxWidth: .infinity, alignment: .leading)
      .font(.system(size: 16))
      .padding(.top, 8)
      Button("Add photos") {
        // TODO use an event for this instead
        project.showPhotoPickerView()
      }
      .buttonStyle(PrimaryButtonStyle(fontSize: 16))
      .padding(.top, 28)
      Spacer()
    }
    .padding(.top, 20)
  }
}

#Preview {
  // let image = UIImage(named: "vecteezy_sewing-machine-icon-style_8737393")!
  // let imageRecord = ProjectImageRecord(from: ProjectImageRecordInput(projectId: 1, filePath: "", thumbnail: "", isDeleted: false, createDate: Date(), updateDate: Date(), path: "", )
  @Previewable @State var viewModel = ProjectViewModel(
    data: ProjectData(
      data: ProjectMetadata(
        id: 1,
        name: "Project Name",
        completed: false,
        createDate: Date(),
        updateDate: Date()
      )
    ),
    projectsNavigation: [],
    projectImages: ProjectImages(projectId: 1, images: [])
  )
  ImagesView(
    model: $viewModel.projectImages
  )
  .environment(viewModel)
  .frame(
    maxWidth: .infinity,
    maxHeight: .infinity,
  )
  .background(.white)
}
