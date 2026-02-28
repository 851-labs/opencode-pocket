import SwiftUI

struct RemoveProjectConfirmationDialog: ViewModifier {
  let isPresented: Binding<Bool>
  let onRemove: () -> Void

  func body(content: Content) -> some View {
    content.confirmationDialog("Remove Project?", isPresented: isPresented) {
      Button("Remove", role: .destructive) {
        onRemove()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This removes the project from the sidebar only. Files and sessions on disk are not deleted.")
    }
  }
}

extension View {
  func removeProjectConfirmationDialog(
    isPresented: Binding<Bool>,
    onRemove: @escaping () -> Void
  ) -> some View {
    modifier(
      RemoveProjectConfirmationDialog(
        isPresented: isPresented,
        onRemove: onRemove
      )
    )
  }
}

#Preview("Remove Project Dialog") {
  @Previewable @State var isPresented = false

  Button("Show Remove Dialog") {
    isPresented = true
  }
  .buttonStyle(.borderedProminent)
  .removeProjectConfirmationDialog(isPresented: $isPresented) {}
  .frame(width: 460, height: 300)
}
