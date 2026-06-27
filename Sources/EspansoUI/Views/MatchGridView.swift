import SwiftUI

struct MatchGridView: View {
    let matches: [EspansoMatch]
    let selectedID: EspansoMatch.ID?
    let isActive: Bool
    let onSelect: (EspansoMatch) -> Void

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(matches) { match in
                MatchGridCell(
                    match: match,
                    isSelected: match.id == selectedID,
                    isActive: isActive,
                    onSelect: { onSelect(match) }
                )
                .id(match.id)
            }
        }
        .padding(8)
    }
}

private struct MatchGridCell: View {
    let match: EspansoMatch
    let isSelected: Bool
    let isActive: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                thumbnail
                Text(match.displayTitle)
                    .font(.caption.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 2)
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var background: Color {
        if isSelected { return Color.accentColor.opacity(0.25) }
        if isHovered { return Color.primary.opacity(0.06) }
        return .clear
    }

    private var thumbnail: some View {
        Color.secondary.opacity(0.1)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let url = match.imageURL {
                    RemoteImage(url: url, isActive: isActive) {
                        Image(systemName: "photo").foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: "photo").foregroundStyle(.secondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
