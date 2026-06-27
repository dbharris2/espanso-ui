import AppKit
import SwiftUI

struct MatchListView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedID: EspansoMatch.ID?

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 6)

            filterPicker
                .padding(.horizontal, 10)
                .padding(.bottom, 6)

            Divider()

            content

            Divider()
            footer
        }
        .frame(width: 420, height: 520)
        .onChange(of: appState.searchText) { _, _ in
            selectedID = appState.filteredMatches.first?.id
        }
        .onChange(of: appState.filter) { _, _ in
            selectedID = appState.filteredMatches.first?.id
        }
        .onChange(of: appState.matches) { _, _ in
            if let current = selectedID, appState.filteredMatches.contains(where: { $0.id == current }) {
                return
            }
            selectedID = appState.filteredMatches.first?.id
        }
        .onAppear {
            selectedID = appState.filteredMatches.first?.id
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search", text: $appState.searchText)
                .textFieldStyle(.plain)
                .onSubmit(activateSelection)
            if !appState.searchText.isEmpty {
                Button {
                    appState.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.1)))
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $appState.filter) {
            ForEach(MatchFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    @ViewBuilder
    private var content: some View {
        if let error = appState.lastError {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("Open Config Folder") { appState.openConfigDirectory() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if appState.filteredMatches.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(appState.matches.isEmpty ? "No matches found in your Espanso config" : "No results")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    if appState.filter == .images {
                        MatchGridView(
                            matches: appState.filteredMatches,
                            selectedID: selectedID,
                            isActive: appState.isMenuPresented,
                            onSelect: { activate($0) }
                        )
                    } else {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(appState.filteredMatches) { match in
                                MatchRowView(
                                    match: match,
                                    isSelected: match.id == selectedID,
                                    isActive: appState.isMenuPresented,
                                    onSelect: { activate(match) }
                                )
                                .id(match.id)
                                .onTapGesture { selectedID = match.id }
                            }
                        }
                        .padding(6)
                    }
                }
                .onChange(of: selectedID) { _, newValue in
                    guard let newValue else { return }
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("\(appState.filteredMatches.count) of \(appState.matches.count)")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Reload") { appState.reload() }
                .buttonStyle(.plain)
                .font(.caption)
            Button("Config…") { appState.openConfigDirectory() }
                .buttonStyle(.plain)
                .font(.caption)
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func activateSelection() {
        guard let id = selectedID,
              let match = appState.filteredMatches.first(where: { $0.id == id })
        else {
            if let first = appState.filteredMatches.first { activate(first) }
            return
        }
        activate(match)
    }

    private func activate(_ match: EspansoMatch) {
        appState.copy(match)
    }
}
