import SwiftUI

struct DeleteSessionConfirmationDialog: ViewModifier {
  let isPresented: Binding<Bool>
  let onDelete: () -> Void

  func body(content: Content) -> some View {
    content.confirmationDialog("Delete Session?", isPresented: isPresented) {
      Button("Delete", role: .destructive) {
        onDelete()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This permanently removes the selected chat session.")
    }
  }
}

extension View {
  func deleteSessionConfirmationDialog(
    isPresented: Binding<Bool>,
    onDelete: @escaping () -> Void
  ) -> some View {
    modifier(
      DeleteSessionConfirmationDialog(
        isPresented: isPresented,
        onDelete: onDelete
      )
    )
  }
}

#Preview("Delete Session Dialog") {
  DeleteSessionConfirmationDialogPreviewHost()
    .frame(width: 460, height: 300)
}

private struct DeleteSessionConfirmationDialogPreviewHost: View {
  @State private var isPresented = false

  var body: some View {
    Button("Show Delete Dialog") {
      isPresented = true
    }
    .buttonStyle(.borderedProminent)
    .deleteSessionConfirmationDialog(isPresented: $isPresented) {}
  }
}
