import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SyncViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Status", value: viewModel.status)
                    Text(viewModel.latestFetchedSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let lastSuccessfulSync = viewModel.lastSuccessfulSync {
                        LabeledContent("Last sync", value: lastSuccessfulSync.formatted(date: .abbreviated, time: .shortened))
                    } else {
                        LabeledContent("Last sync", value: "Never")
                    }
                }

                Section {
                    Button {
                        viewModel.requestPermissions()
                    } label: {
                        Label("Allow Health Access", systemImage: "heart.text.square")
                    }

                    Button {
                        viewModel.syncNow()
                    } label: {
                        Label(viewModel.isSyncing ? "Syncing..." : "Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(viewModel.isSyncing)
                }
            }
            .navigationTitle("Health Sync")
            .task {
                await viewModel.sync(daysBack: viewModel.lastSuccessfulSync == nil ? 30 : 7)
            }
        }
    }
}

#Preview {
    ContentView()
}
