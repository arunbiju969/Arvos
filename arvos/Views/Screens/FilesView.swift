//
//  FilesView.swift
//  arvos
//
//  Browse and manage recorded files
//

import SwiftUI

struct FilesView: View {
    @StateObject private var recordingManager = RecordingManager()
    @State private var recordings: [SessionMetadata] = []
    @State private var showingDeleteAlert = false
    @State private var selectedRecording: SessionMetadata?

    var body: some View {
        NavigationStack {
            Group {
                if recordings.isEmpty {
                    emptyState
                } else {
                    recordingsList
                }
            }
            .navigationTitle("Recordings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: loadRecordings) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert("Delete Recording", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let recording = selectedRecording {
                        deleteRecording(recording)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this recording? This action cannot be undone.")
            }
            .onAppear {
                loadRecordings()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Recordings")
                .font(.title2.weight(.medium))

            Text("Your recorded sessions will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Recordings List

    private var recordingsList: some View {
        List {
            ForEach(recordings, id: \.sessionId) { recording in
                RecordingRow(recording: recording)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            selectedRecording = recording
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Actions

    private func loadRecordings() {
        recordings = recordingManager.listRecordings()
    }

    private func deleteRecording(_ recording: SessionMetadata) {
        do {
            try recordingManager.deleteRecording(sessionId: recording.sessionId)
            loadRecordings()
        } catch {
            print("Failed to delete recording: \(error)")
        }
    }
}

// MARK: - Recording Row

struct RecordingRow: View {
    let recording: SessionMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: recording.mode.icon)
                    .foregroundColor(Theme.accent)

                Text(recording.mode.rawValue)
                    .font(.headline)

                Spacer()

                Text(formatDate(recording.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                Label(formatDuration(recording.duration), systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Label(formatFileSize(recording.fileSize), systemImage: "doc")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Sensor counts
            HStack(spacing: 12) {
                if recording.sensorCounts.cameraFrames > 0 {
                    SensorCountBadge(icon: "camera", count: recording.sensorCounts.cameraFrames)
                }

                if recording.sensorCounts.depthFrames > 0 {
                    SensorCountBadge(icon: "cube", count: recording.sensorCounts.depthFrames)
                }

                if recording.sensorCounts.imuSamples > 0 {
                    SensorCountBadge(icon: "gyroscope", count: recording.sensorCounts.imuSamples)
                }

                if recording.sensorCounts.poseSamples > 0 {
                    SensorCountBadge(icon: "location", count: recording.sensorCounts.poseSamples)
                }

                if recording.sensorCounts.gpsSamples > 0 {
                    SensorCountBadge(icon: "map", count: recording.sensorCounts.gpsSamples)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / (1024.0 * 1024.0)
        if mb < 1.0 {
            let kb = Double(bytes) / 1024.0
            return String(format: "%.0f KB", kb)
        }
        return String(format: "%.1f MB", mb)
    }
}

struct SensorCountBadge: View {
    let icon: String
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text(formatCount(count))
                .font(.caption2)
        }
        .foregroundColor(.secondary)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}

#Preview {
    FilesView()
}
