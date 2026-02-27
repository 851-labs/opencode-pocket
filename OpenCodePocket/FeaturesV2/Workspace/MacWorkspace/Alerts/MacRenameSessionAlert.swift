#if os(macOS)
  import Foundation
  import SwiftUI

  struct MacRenameSessionAlert: ViewModifier {
    let isPresented: Binding<Bool>
    let title: Binding<String>
    let textFieldID: UUID
    let onSave: () -> Void

    private var isSaveDisabled: Bool {
      title.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func body(content: Content) -> some View {
      content.alert("Rename Session", isPresented: isPresented) {
        TextField("Session title", text: title)
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
    func macRenameSessionAlert(
      isPresented: Binding<Bool>,
      title: Binding<String>,
      textFieldID: UUID,
      onSave: @escaping () -> Void
    ) -> some View {
      modifier(
        MacRenameSessionAlert(
          isPresented: isPresented,
          title: title,
          textFieldID: textFieldID,
          onSave: onSave
        )
      )
    }
  }

  #Preview("Rename Session Alert") {
    MacRenameSessionAlertPreviewHost()
      .frame(width: 460, height: 300)
  }

  private struct MacRenameSessionAlertPreviewHost: View {
    @State private var isPresented = false
    @State private var title = "Session title"
    @State private var textFieldID = UUID()

    var body: some View {
      Button("Show Rename Alert") {
        title = "Session title"
        textFieldID = UUID()
        isPresented = true
      }
      .buttonStyle(.borderedProminent)
      .macRenameSessionAlert(
        isPresented: $isPresented,
        title: $title,
        textFieldID: textFieldID
      ) {}
    }
  }
#endif
