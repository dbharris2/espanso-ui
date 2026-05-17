import Foundation
import SwiftUI

struct MatchRowView: View {
    let match: EspansoMatch
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                preview
                    .frame(width: 64, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                VStack(alignment: .leading, spacing: 2) {
                    Text(match.displayTitle)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                    if match.triggers.count > 1 {
                        Text(match.triggers.dropFirst().joined(separator: " · "))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(background)
            )
            .foregroundStyle(isSelected ? Color.white : .primary)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private var preview: some View {
        if let url = match.imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().scaledToFill()
                case .failure:
                    placeholder(systemImage: "photo")
                case .empty:
                    placeholder(systemImage: "photo")
                @unknown default:
                    placeholder(systemImage: "photo")
                }
            }
        } else {
            placeholder(systemImage: "text.alignleft")
        }
    }

    private func placeholder(systemImage: String) -> some View {
        ZStack {
            Color.secondary.opacity(0.1)
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
        }
    }

    private var subtitle: String {
        if match.isImage { return "Image" }
        return match.replace
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: CharacterSet.whitespaces)
    }

    private var background: Color {
        if isSelected { return Color.accentColor }
        if isHovered { return Color.primary.opacity(0.06) }
        return .clear
    }
}
