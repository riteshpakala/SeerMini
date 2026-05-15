import Foundation
import Vapor

struct SeerRequest: Content, Codable {
    let ownerId: String
    let group: Seer.Group?
    let groups: [Seer.Group]?
    let tags: [String]?
    let aggregate: Bool?
    let scope: SeerRequestScope?
    let requestID: String?

    init(ownerId: String,
         group: Seer.Group? = nil,
         groups: [Seer.Group]? = nil,
         tags: [String]? = nil,
         aggregate: Bool? = nil,
         scope: SeerRequestScope? = nil,
         requestID: String? = nil) {
        self.ownerId = ownerId
        self.group = group
        self.groups = groups
        self.tags = tags
        self.aggregate = aggregate
        self.scope = scope
        self.requestID = requestID
    }

    enum CodingKeys: String, CodingKey {
        case ownerId = "owner_id"
        case group
        case groups
        case tags
        case aggregate
        case scope
        case requestID = "request_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ownerId   = try c.decode(String.self,                    forKey: .ownerId)
        group     = try c.decodeIfPresent(Seer.Group.self,       forKey: .group)
        groups    = try c.decodeIfPresent([Seer.Group].self,     forKey: .groups)
        tags      = try c.decodeIfPresent([String].self,         forKey: .tags)
        aggregate = try c.decodeIfPresent(Bool.self,             forKey: .aggregate)
        scope     = try c.decodeIfPresent(SeerRequestScope.self, forKey: .scope)
        requestID = try c.decodeIfPresent(String.self,           forKey: .requestID)
    }

    /// In SeerMini there is no auth middleware — ownerId comes directly from the body.
    func from(_ req: Request) throws -> SeerRequest {
        return .init(
            ownerId: self.ownerId.lowercased(),
            group: self.group,
            groups: self.groups,
            tags: self.tags,
            aggregate: self.aggregate,
            scope: self.scope,
            requestID: req.id
        )
    }
}

enum SeerRequestScope: String, Codable {
    case global
    case personal
}
