import OpenCodeModels
import SwiftUI

#if os(iOS)

  struct TurnDiffSummaryCard: View {
    let diffs: [FileDiff]
    @State private var isExpanded = false

    private var dedupedDiffs: [FileDiff] {
      var seen: Set<String> = []
      return diffs
        .reversed()
        .filter { seen.insert($0.file).inserted }
        .reversed()
    }

    private func isExpandedBinding(for file: String) -> Binding<Bool> {
      Binding(
        get: {
          expandedFiles.contains(file)
        },
        set: { value in
          if value {
            expandedFiles.insert(file)
            return
          }
          expandedFiles.remove(file)
        }
      )
    }

    @State private var expandedFiles: Set<String> = []

    var body: some View {
      DisclosureGroup(isExpanded: $isExpanded) {
        VStack(spacing: 8) {
          ForEach(dedupedDiffs) { diff in
            DisclosureGroup(isExpanded: isExpandedBinding(for: diff.file)) {
              VStack(alignment: .leading, spacing: 8) {
                DiffSnippet(title: "Before", text: diff.before)
                DiffSnippet(title: "After", text: diff.after)
              }
              .padding(.top, 6)
            } label: {
              HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                  DiffPathLabel(path: diff.file)
                  Text(diff.status?.capitalized ?? "Modified")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                  Text("+\(diff.additionsCount)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.green)
                  Text("-\(diff.deletionsCount)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.red)
                }
              }
            }
          }
        }
        .padding(.top, 6)
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "doc.text")
            .font(.caption)
          Text("Modified \(dedupedDiffs.count) file\(dedupedDiffs.count == 1 ? "" : "s")")
            .font(.caption.weight(.semibold))
          Spacer(minLength: 0)
        }
      }
      .padding(10)
      .background(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(Color.secondary.opacity(0.08))
      )
    }
  }

  private struct DiffPathLabel: View {
    let path: String

    private var split: (directory: String?, fileName: String) {
      let parts = path.split(separator: "/", omittingEmptySubsequences: false)
      guard let last = parts.last else {
        return (nil, path)
      }

      let fileName = String(last)
      let prefix = parts.dropLast().joined(separator: "/")
      if prefix.isEmpty {
        return (nil, fileName)
      }
      return (prefix + "/", fileName)
    }

    var body: some View {
      HStack(spacing: 0) {
        if let directory = split.directory {
          Text(directory)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
        }

        Text(split.fileName)
          .font(.caption.weight(.semibold))
          .lineLimit(1)
          .truncationMode(.middle)
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(path)
    }
  }

  private struct DiffSnippet: View {
    let title: String
    let text: String

    var body: some View {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)

        ScrollView(.horizontal) {
          Text(text)
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.secondary.opacity(0.07))
        )
      }
    }
  }

#endif
