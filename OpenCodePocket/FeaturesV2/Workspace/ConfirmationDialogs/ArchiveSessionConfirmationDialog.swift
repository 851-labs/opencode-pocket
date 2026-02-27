import SwiftUI

struct ArchiveSessionConfirmationDialog: ViewModifier {
  let isPresented: Binding<Bool>
  let onArchive: () -> Void

  func body(content: Content) -> some View {
    content.confirmationDialog("Archive Session?", isPresented: isPresented) {
      Button("Archive") {
        onArchive()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("You can unarchive this session later from Settings > Archived.")
    }
  }
}

extension View {
  func archiveSessionConfirmationDialog(
    isPresented: Binding<Bool>,
    onArchive: @escaping () -> Void
  ) -> some View {
    modifier(
      ArchiveSessionConfirmationDialog(
        isPresented: isPresented,
        onArchive: onArchive
      )
    )
  }
}

#Preview("Archive Session Dialog") {
  ArchiveSessionConfirmationDialogPreviewHost()
    .frame(width: 460, height: 300)
}

private struct ArchiveSessionConfirmationDialogPreviewHost: View {
  @State private var isPresented = false

  var body: some View {
    Button("Show Archive Dialog") {
      isPresented = true
    }
    .buttonStyle(.borderedProminent)
    .archiveSessionConfirmationDialog(isPresented: $isPresented) {}
  }
}
