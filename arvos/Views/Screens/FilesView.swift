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
    @State private var showingShareSheet = false
    @State private var shareItems: [URL] = []
    @State private var showingDetailView = false

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
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .alert("Delete Recording", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    selectedRecording = nil
                }
                Button("Delete", role: .destructive) {
                    if let recording = selectedRecording {
                        deleteRecording(recording)
                        selectedRecording = nil
                    }
                }
            } message: {
                if let recording = selectedRecording {
                    Text("Are you sure you want to delete \"\(recording.mode.rawValue)\" from \(formatDate(recording.startTime))? This action cannot be undone.")
                } else {
                    Text("Are you sure you want to delete this recording? This action cannot be undone.")
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: shareItems)
            }
            .sheet(isPresented: $showingDetailView) {
                if let recording = selectedRecording {
                    RecordingDetailView(
                        recording: recording,
                        onDelete: {
                            showingDetailView = false
                            showingDeleteAlert = true
                        },
                        onShare: {
                            showingDetailView = false
                            shareRecording(recording)
                        }
                    )
                }
            }
            .onAppear {
                loadRecordings()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "tray")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("No Recordings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Your recorded sessions will appear here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding()
    }

    // MARK: - Recordings List

    private var recordingsList: some View {
        List {
            ForEach(recordings, id: \.sessionId) { recording in
                Button {
                    selectedRecording = recording
                    showingDetailView = true
                } label: {
                    RecordingRow(recording: recording)
                }
                .buttonStyle(PlainButtonStyle())
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        selectedRecording = recording
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        shareRecording(recording)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        selectedRecording = recording
                        showingDetailView = true
                    } label: {
                        Label("Details", systemImage: "info.circle")
                    }
                    .tint(.gray)
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
            print("❌ Failed to delete recording: \(error)")
            // Could show an error alert here
        }
    }
    
    private func shareRecording(_ recording: SessionMetadata) {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDir = documents.appendingPathComponent(Constants.Recording.recordingsDirectory)
        let sessionDir = recordingsDir.appendingPathComponent(recording.sessionId)
        
        // Get all files in the session directory
        do {
            let files = try FileManager.default.contentsOfDirectory(at: sessionDir, includingPropertiesForKeys: nil)
            shareItems = files
            showingShareSheet = true
        } catch {
            print("❌ Failed to get files for sharing: \(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [URL]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Recording Row

struct RecordingRow: View {
    let recording: SessionMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: recording.mode.icon)
                    .foregroundColor(.primary)

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

// MARK: - Recording Detail View

struct RecordingDetailView: View {
    let recording: SessionMetadata
    let onDelete: () -> Void
    let onShare: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var filesList: [FileItem] = []

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height

                ScrollView {
                    VStack(spacing: isLandscape ? 20 : 24) {
                    // Header Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: recording.mode.icon)
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.accentColor)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(recording.mode.rawValue)
                                    .font(.title2)
                                    .fontWeight(.semibold)

                                Text(formatDate(recording.startTime))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                        )

                        // Session Info
                        VStack(spacing: 12) {
                            DetailRow(icon: "clock.fill", label: "Duration", value: formatDuration(recording.duration))
                            DetailRow(icon: "doc.fill", label: "File Size", value: formatFileSize(recording.fileSize))
                            DetailRow(icon: "calendar", label: "Started", value: formatFullDate(recording.startTime))

                            if let endTime = recording.endTime {
                                DetailRow(icon: "calendar.badge.checkmark", label: "Ended", value: formatFullDate(endTime))
                            }

                            DetailRow(icon: "folder.fill", label: "Session ID", value: String(recording.sessionId.prefix(8)))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                    }

                    // Sensor Counts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sensor Data")
                            .font(.headline)
                            .padding(.horizontal, 4)

                        VStack(spacing: 10) {
                            if recording.sensorCounts.cameraFrames > 0 {
                                SensorDetailRow(icon: "camera.fill", label: "Camera Frames", count: recording.sensorCounts.cameraFrames)
                            }

                            if recording.sensorCounts.depthFrames > 0 {
                                SensorDetailRow(icon: "cube.fill", label: "Depth Frames", count: recording.sensorCounts.depthFrames)
                            }

                            if recording.sensorCounts.imuSamples > 0 {
                                SensorDetailRow(icon: "gyroscope", label: "IMU Samples", count: recording.sensorCounts.imuSamples)
                            }

                            if recording.sensorCounts.poseSamples > 0 {
                                SensorDetailRow(icon: "location.fill", label: "Pose Samples", count: recording.sensorCounts.poseSamples)
                            }

                            if recording.sensorCounts.gpsSamples > 0 {
                                SensorDetailRow(icon: "map.fill", label: "GPS Samples", count: recording.sensorCounts.gpsSamples)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                    }

                    // File Formats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("File Formats")
                            .font(.headline)
                            .padding(.horizontal, 4)

                        VStack(spacing: 8) {
                            ForEach(recording.fileFormats, id: \.self) { format in
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(.accentColor)
                                    Text(format.uppercased())
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.medium)

                                    Spacer()

                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.secondarySystemBackground))
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                        )
                    }

                    // Files List
                    if !filesList.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Files")
                                .font(.headline)
                                .padding(.horizontal, 4)

                            VStack(spacing: 8) {
                                ForEach(filesList) { file in
                                    HStack {
                                        Image(systemName: file.icon)
                                            .foregroundColor(.secondary)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(file.name)
                                                .font(.system(.body, design: .monospaced))
                                                .lineLimit(1)

                                            Text(formatFileSize(file.size))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(.secondarySystemBackground))
                                    )
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(.systemBackground))
                            )
                        }
                    }

                    // Action Buttons
                    if isLandscape {
                        HStack(spacing: 12) {
                            Button {
                                onShare()
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Share Recording")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.accentColor)
                                )
                            }

                            Button(role: .destructive) {
                                onDelete()
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Delete Recording")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.red)
                                )
                            }
                        }
                        .padding(.top, 8)
                    } else {
                        VStack(spacing: 12) {
                            Button {
                                onShare()
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Share Recording")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.accentColor)
                                )
                            }

                            Button(role: .destructive) {
                                onDelete()
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Delete Recording")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.red)
                                )
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(isLandscape ? 16 : 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Recording Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadFiles()
            }
            }
        }
    }

    private func loadFiles() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsDir = documents.appendingPathComponent(Constants.Recording.recordingsDirectory)
        let sessionDir = recordingsDir.appendingPathComponent(recording.sessionId)

        do {
            let urls = try FileManager.default.contentsOfDirectory(at: sessionDir, includingPropertiesForKeys: [.fileSizeKey])
            filesList = urls.compactMap { url in
                guard let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey]),
                      let fileSize = resourceValues.fileSize else {
                    return nil
                }

                return FileItem(
                    name: url.lastPathComponent,
                    size: Int64(fileSize),
                    icon: iconForFile(url.lastPathComponent)
                )
            }.sorted { $0.name < $1.name }
        } catch {
            print("Failed to load files: \(error)")
        }
    }

    private func iconForFile(_ filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "mcap":
            return "doc.badge.gearshape"
        case "json":
            return "doc.text"
        case "ply":
            return "cube.fill"
        case "h264", "mp4", "mov":
            return "video.fill"
        case "jpg", "jpeg", "png":
            return "photo.fill"
        default:
            return "doc"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
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

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    let icon: String
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct SensorDetailRow: View {
    let icon: String
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)

            Spacer()

            Text(formatCount(count))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000.0)
        } else if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}

#Preview {
    FilesView()
}
