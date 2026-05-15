import Foundation

actor SeerAPI {
    let baseURL: String
    let ownerId: String
    let groupId: String
    let groupLabel: String

    init(baseURL: String, ownerId: String, groupId: String, groupLabel: String = "Demo") {
        self.baseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        self.ownerId = ownerId
        self.groupId = groupId
        self.groupLabel = groupLabel
    }

    // MARK: - Health check

    func isReachable() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else { return false }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Batch embeddings

    func embed(text: String) async throws {
        guard let url = URL(string: "\(baseURL)/v1/batch/embeddings") else {
            throw APIError.invalidURL
        }

        let body = EmbedRequest(
            inputs: [[text]],
            sanitize: true,
            seer: EmbedRequest.SeerParams(
                ownerId: ownerId,
                group: EmbedRequest.GroupParams(
                    id: groupId, label: groupLabel, ownerId: ownerId, documents: []
                )
            )
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        req.timeoutInterval = 120

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse(0) }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.badResponse(http.statusCode, msg)
        }
    }

    // MARK: - Search

    func search(query: String) async throws -> [SearchResult] {
        guard let url = URL(string: "\(baseURL)/v1/search") else {
            throw APIError.invalidURL
        }

        let body = SearchRequest(
            query: query,
            seer: SearchRequest.SeerParams(ownerId: ownerId, scope: "personal")
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        req.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse(0) }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.badResponse(http.statusCode, msg)
        }

        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.texts.enumerated().map { i, text in
            let ref = decoded.references.indices.contains(i) ? decoded.references[i] : nil
            return SearchResult(
                id: "result-\(i)",
                text: text,
                documentId: ref?.id ?? "",
                partitionId: ref?.partitionId ?? "",
                ownerId: ref?.ownerId ?? "",
                distance: nil
            )
        }
    }

    // MARK: - Errors

    enum APIError: LocalizedError {
        case invalidURL
        case badResponse(Int, String = "")

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid server URL. Check Settings."
            case .badResponse(let code, let msg):
                return "Server error \(code)\(msg.isEmpty ? "" : ": \(msg.prefix(120))")"
            }
        }
    }

    // MARK: - Codable types (private)

    private struct EmbedRequest: Encodable {
        let inputs: [[String]]
        let sanitize: Bool
        let seer: SeerParams

        struct SeerParams: Encodable {
            let ownerId: String
            let group: GroupParams
            enum CodingKeys: String, CodingKey { case ownerId = "owner_id", group }
        }

        struct GroupParams: Encodable {
            let id, label, ownerId: String
            let documents: [String]
            enum CodingKeys: String, CodingKey { case id, label, ownerId = "owner_id", documents }
        }
    }

    private struct SearchRequest: Encodable {
        let query: String
        let seer: SeerParams

        struct SeerParams: Encodable {
            let ownerId: String
            let scope: String
            enum CodingKeys: String, CodingKey { case ownerId = "owner_id", scope }
        }
    }

    private struct SearchResponse: Decodable {
        let texts: [String]
        let references: [Reference]

        struct Reference: Decodable {
            let id: String
            let partitionId: String
            let ownerId: String
            enum CodingKeys: String, CodingKey {
                case id
                case partitionId = "partition_id"
                case ownerId     = "owner_id"
            }
        }
    }
}
