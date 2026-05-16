import Vapor

private struct LibraryRequest: Content {
    let ownerId: String
    enum CodingKeys: String, CodingKey { case ownerId = "owner_id" }
}

struct LibraryResponse: Content {
    let groups: [Seer.Group]
}

func registerLibraryRoute(_ app: RoutesBuilder, _ seer: Seer) {
    app.post("v1", "library") { req async throws -> LibraryResponse in
        let body = try req.content.decode(LibraryRequest.self)
        let groups = seer.groups(for: body.ownerId)
        return LibraryResponse(groups: groups)
    }
}
