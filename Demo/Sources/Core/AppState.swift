import SwiftUI

@MainActor
final class AppState: ObservableObject {

    // MARK: - Library state

    @Published var documents: [SeerDocument] = []
    @Published var uploadingFiles: [UploadingFile] = []

    // MARK: - Search state

    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    @Published var searchError: String?
    @Published var lastQuery = ""

    // MARK: - Server state

    @Published var serverReachable: Bool? = nil

    // MARK: - Persisted config

    @AppStorage("seerServerURL") var serverURL: String = "http://127.0.0.1:8080"
    @AppStorage("seerOwnerId")  var ownerId:   String = "seer-demo"
    @AppStorage("seerGroupId")  var groupId:   String = "demo-group"

    // MARK: - API

    var api: SeerAPI {
        SeerAPI(baseURL: serverURL, ownerId: ownerId, groupId: groupId, groupLabel: "Demo")
    }

    // MARK: - Health check

    func checkHealth() async {
        serverReachable = await api.isReachable()
    }

    // MARK: - Upload

    func uploadFiles(urls: [URL]) {
        let newFiles = urls.map { UploadingFile(url: $0) }
        uploadingFiles.append(contentsOf: newFiles)
        for file in newFiles {
            let fileId = file.id
            Task { await self.processFile(id: fileId) }
        }
    }

    private func processFile(id: UUID) async {
        guard let idx = uploadingFiles.firstIndex(where: { $0.id == id }) else { return }
        let url = uploadingFiles[idx].url

        setStatus(id: id, .reading)

        let text: String
        do {
            text = try await Task.detached(priority: .userInitiated) {
                let raw = try FileReader.extractText(from: url)
                return TextSanitizer.sanitize(raw)
            }.value
        } catch {
            setStatus(id: id, .error(error.localizedDescription))
            return
        }

        guard !text.isEmpty else {
            setStatus(id: id, .error("Empty file"))
            return
        }

        setStatus(id: id, .embedding)

        do {
            let currentAPI = api
            try await currentAPI.embed(text: text)

            let doc = SeerDocument(
                id: UUID().uuidString,
                name: url.lastPathComponent,
                url: url,
                uploadedAt: Date()
            )
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                documents.append(doc)
            }
            setStatus(id: id, .done)

            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation(.easeOut(duration: 0.3)) {
                uploadingFiles.removeAll { $0.id == id }
            }
        } catch {
            setStatus(id: id, .error(error.localizedDescription))
        }
    }

    private func setStatus(id: UUID, _ status: UploadingFile.UploadStatus) {
        if let idx = uploadingFiles.firstIndex(where: { $0.id == id }) {
            uploadingFiles[idx].status = status
        }
    }

    // MARK: - Search

    func search(query: String) async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }

        isSearching = true
        searchError = nil
        lastQuery = q

        do {
            let currentAPI = api
            let results = try await currentAPI.search(query: q)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                searchResults = results
            }
        } catch {
            searchError = error.localizedDescription
            searchResults = []
        }
        isSearching = false
    }

    func clearSearch() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
            searchResults = []
            searchError = nil
            lastQuery = ""
        }
    }
}
