import SwiftUI

struct FabricsView: View {
  @Environment(\.db) private var db
  @Environment(\.settings) var settings
  @Environment(StateStore.self) var stateStore
  @State var showAddFabricDialog = true

  func handleDismiss() {
    print("dismis")
  }

  var body: some View {
    @Bindable var storeBinding = stateStore
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
      FabricInputView()
    }
    .onAppear {
      stateStore.send(event: .fabrics(.loadFabrics), db: db)
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
