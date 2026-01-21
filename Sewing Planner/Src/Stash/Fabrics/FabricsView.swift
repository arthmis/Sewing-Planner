import SwiftUI

struct FabricsView: View {
  @Environment(\.db) private var db
  @Environment(\.settings) var settings
  @Environment(Store.self) var store
  @State var showAddFabricDialog = false

  func handleDismiss() {
    print("dismis")
  }

  var body: some View {
    @Bindable var storeBinding = store
    VStack {
      Button("Add Fabric") {
        showAddFabricDialog = true
      }
      ScrollView {
        LazyVStack(alignment: .center, spacing: 12) {
          ForEach(
            $storeBinding.stashState.fabrics.fabrics,
            id: \.self.fabric.id
          ) { $fabric in
            FabricCardView(
              fabric: fabric,
              // projectsNavigation: $storeBinding.projectsState.navigation
            )
          }
        }
        .padding(.bottom, 12)
      }
    }.sheet(isPresented: $showAddFabricDialog, onDismiss: handleDismiss) {
      NavigationStack {
        FabricInputView()
          .navigationBarItems(
            leading: Button("Cancel") {
              showAddFabricDialog = false
            }
          )
          .navigationTitle("New Fabric")
          .navigationBarTitleDisplayMode(.inline)
          .navigationBarItems(trailing: Button("Add") { print("add") })
      }
    }
  }
}

struct FabricCardView: View {
  let fabric: FabricModel
  var body: some View {
    Button(fabric.fabric.name) {
      print("Do something")
    }
  }
}
