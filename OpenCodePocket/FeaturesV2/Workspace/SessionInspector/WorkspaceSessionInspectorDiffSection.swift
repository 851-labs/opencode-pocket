import OpenCodeModels
import SwiftUI

struct WorkspaceSessionInspectorDiffSection: View {
  let items: [FileDiff]
  let isExpanded: Bool
  let onToggleExpanded: () -> Void

  var body: some View {
    WorkspaceSessionInspectorCollapsibleSection(
      title: "Modified Files",
      rowCount: items.count,
      collapsedSummary: nil,
      accessibilityID: "workspace.inspector.diff",
      isExpanded: isExpanded,
      onToggle: onToggleExpanded
    ) {
      ForEach(items) { diff in
        HStack(alignment: .top, spacing: 8) {
          Text(diff.file)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)

          Spacer(minLength: 6)

          HStack(spacing: 6) {
            if diff.additionsCount > 0 {
              Text("+\(diff.additionsCount)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green)
            }

            if diff.deletionsCount > 0 {
              Text("-\(diff.deletionsCount)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red)
            }
          }
        }
      }
    }
  }
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
      isExpanded: true,
      onToggleExpanded: {}
    )
  }
  .formStyle(.grouped)
  .frame(width: 340, height: 320)
}
