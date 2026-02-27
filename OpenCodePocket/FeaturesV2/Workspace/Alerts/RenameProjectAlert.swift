import Foundation
import SwiftUI

struct RenameProjectAlert: ViewModifier {
  let isPresented: Binding<Bool>
  let name: Binding<String>
  let textFieldID: UUID
  let onSave: () -> Void

  private var isSaveDisabled: Bool {
    name.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func body(content: Content) -> some View {
    content.alert("Rename Project", isPresented: isPresented) {
      TextField("Project name", text: name)
        .id(textFieldID)
      Button("Cancel", role: .cancel) {}
      Button("Save") {
        onSave()
      }
      .keyboardShortcut(.defaultAction)
      .disabled(isSaveDisabled)
    }
  }
}

extension View {
  func renameProjectAlert(
    isPresented: Binding<Bool>,
    name: Binding<String>,
    textFieldID: UUID,
    onSave: @escaping () -> Void
  ) -> some View {
    modifier(
      RenameProjectAlert(
        isPresented: isPresented,
        name: name,
        textFieldID: textFieldID,
        onSave: onSave
      )
    )
  }
}

#Preview("Rename Project Alert") {
  RenameProjectAlertPreviewHost()
    .frame(width: 460, height: 300)
}

private struct RenameProjectAlertPreviewHost: View {
  @State private var isPresented = false
  @State private var name = "Project name"
  @State private var textFieldID = UUID()

  var body: some View {
    Button("Show Rename Alert") {
      name = "Project name"
      textFieldID = UUID()
      isPresented = true
    }
    .buttonStyle(.borderedProminent)
    .renameProjectAlert(
      isPresented: $isPresented,
      name: $name,
      textFieldID: textFieldID
    ) {}
  }
}
