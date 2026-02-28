import OpenCodeModels
import SwiftUI

#if os(macOS)
  import AppKit
  import UniformTypeIdentifiers
#endif

struct WorkspaceSessionInspectorDiffSection: View {
  let items: [FileDiff]
  let rootDirectory: String?
  @Binding var isExpanded: Bool

  var body: some View {
    WorkspaceSessionInspectorCollapsibleSection(
      title: "Modified Files",
      collapsedSummary: nil,
      accessibilityID: "workspace.inspector.diff",
      isExpanded: $isExpanded
    ) {
      ForEach(items) { diff in
        LabeledContent {
          HStack(spacing: 6) {
            if diff.additionsCount > 0 {
              Text("+\(diff.additionsCount)")
                .fontWeight(.medium)
                .foregroundStyle(.green)
            }

            if diff.deletionsCount > 0 {
              Text("-\(diff.deletionsCount)")
                .fontWeight(.medium)
                .foregroundStyle(.red)
            }
          }
        } label: {
          Label {
            Text(diff.file)
              .lineLimit(1)
          } icon: {
            fileIcon(for: diff.file)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func fileIcon(for path: String) -> some View {
    #if os(macOS)
      Image(nsImage: nsImageFileIcon(for: path))
        .resizable()
        .frame(width: 16, height: 16)
    #else
      Image(systemName: "doc")
    #endif
  }

  #if os(macOS)
    private func nsImageFileIcon(for path: String) -> NSImage {
      let resolvedPath = resolvedFilePath(for: path)

      if FileManager.default.fileExists(atPath: resolvedPath) {
        let icon = NSWorkspace.shared.icon(forFile: resolvedPath)
        icon.size = NSSize(width: 16, height: 16)
        return icon
      }

      let pathExtension = URL(fileURLWithPath: path).pathExtension
      let contentType = UTType(filenameExtension: pathExtension) ?? .data
      let icon = NSWorkspace.shared.icon(for: contentType)
      icon.size = NSSize(width: 16, height: 16)
      return icon
    }

    private func resolvedFilePath(for path: String) -> String {
      if (path as NSString).isAbsolutePath {
        return path
      }

      guard let rootDirectory else {
        return path
      }

      return URL(fileURLWithPath: rootDirectory)
        .appendingPathComponent(path)
        .path
    }
  #endif
}

#Preview("Diff Section") {
  Form {
    WorkspaceSessionInspectorDiffSection(
      items: [
        FileDiff(
          file: "apps/api/components/pipelines/models/pipeline_version_run.rb",
          before: "a1",
          after: "b1",
          additions: 129,
          deletions: 13,
          status: "modified"
        ),
        FileDiff(
          file: "packages/ui/src/components/image/index.tsx",
          before: "a2",
          after: "b2",
          additions: 46,
          deletions: 31,
          status: "modified"
        ),
        FileDiff(
          file: "packages/utils/src/imgproxy.ts",
          before: "a3",
          after: "b3",
          additions: 8,
          deletions: 1,
          status: "modified"
        ),
      ],
      rootDirectory: nil,
      isExpanded: .constant(true)
    )
  }
  .formStyle(.grouped)
  .frame(width: 340, height: 320)
}
