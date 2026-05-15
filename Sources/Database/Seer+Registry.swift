import Foundation

extension Seer {
    func initializeRegistry() {
        let storage = registryStore
        var registry: SeerRegistry = storage.restore() ?? .init()

        let walURL = FilePersistence.getDefaultURL().appendingPathComponent("registry-wal")
        if let w = try? RegistryWAL(url: walURL),
           let records = try? w.readAll(), !records.isEmpty {
            for record in records { record.apply(to: &registry) }
            logger.info(
                "Registry Init",
                "⚜️ Replayed \(records.count) WAL record(s)",
                service: .seer
            )
        }

        if registry.availableDocumentIds.isEmpty && !registry.documentAccess.isEmpty {
            registry.availableDocumentIds = Set(
                registry.documentAccess.compactMap { $0.value == .available ? $0.key : nil }
            )
            storage.save(state: registry)
        }

        let allDocumentIds = Array(registry.documentOwners.keys)
        var initial: [DocumentID: Seer.Document] = [:]
        var orphanedIds: [DocumentID] = []

        for documentId in allDocumentIds {
            let store = documentStore(for: documentId)
            guard FileManager.default.fileExists(atPath: store.url.path()) else {
                orphanedIds.append(documentId)
                continue
            }
            if let document: Seer.Document = store.restore() {
                initial[documentId] = document
            } else {
                orphanedIds.append(documentId)
            }
        }

        if !orphanedIds.isEmpty {
            for id in orphanedIds { registry.removeOrphaned(documentId: id) }
            storage.save(state: registry)
            logger.info(
                "Registry Init",
                "⚠️ Removed \(orphanedIds.count) orphaned document(s)",
                service: .seer
            )
        }

        var staleGroupCount = 0
        for (owner, ownerGroups) in registry.ownersGroups {
            let cleaned = ownerGroups.filter { registry.groupOwners[$0.id] == owner }
            if cleaned.count != ownerGroups.count {
                staleGroupCount += ownerGroups.count - cleaned.count
                registry.ownersGroups[owner] = cleaned
            }
        }
        if staleGroupCount > 0 {
            storage.save(state: registry)
            logger.warning(
                "⚠️ Removed \(staleGroupCount) stale group reference(s) from ownersGroups",
                service: .seer
            )
        }

        registryMutator.seed(registry)
        documentCache.seed(initial)
        logger.debug(
            "Registry Init",
            "⚜️ Seer Registry initialized — \(allDocumentIds.count - orphanedIds.count) document(s) pre-cached",
            service: .seer
        )
    }

    var registryStore: FilePersistence {
        FilePersistence(key: "registry", kind: .basic, logger: logger.base)
    }
}

extension Seer {
    func register(_ document: Seer.Document,
                  group: Seer.Group?,
                  update: SeerUpdate? = nil,
                  ownerId: String) async {
        await registryMutator.register(document, group: group, ownerId: ownerId)

        if let update, update.operation == .remove {
            await remove(documentId: update.documentId, group: group, ownerId: ownerId)
        }
    }

    @discardableResult
    func updateDocumentAccess(_ id: String,
                              ownerId: String,
                              access: SeerRegistry.Access) async -> Bool {
        let updated = await registryMutator.updateDocumentAccess(id: id, ownerId: ownerId, access: access)
        if !updated {
            logger.info("Registry", "Owner does not own this document.", service: .seer)
        }
        return updated
    }
}

extension Seer {
    nonisolated func groups(for ownerId: OwnerID) -> [Seer.Group] {
        let registry = self.registry
        let owner = SeerRegistry.Owner(id: ownerId)
        let groups = registry?.ownersGroups[owner] ?? []

        var groupsResponse: [Seer.Group] = []
        if let registry {
            for group in groups {
                guard group.ownerId == owner.id else { continue }
                if let builtGroup = buildGroup(groupId: group.id, registry: registry) {
                    groupsResponse.append(builtGroup)
                }
            }
        }
        return groupsResponse
    }

    func stats(for documentId: DocumentID) -> Seer.DocumentStats? {
        registry?.documentStats[documentId]
    }

    @discardableResult
    func updateGroupAccess(_ id: String,
                           ownerId: String,
                           access: SeerRegistry.Access) async -> Bool {
        let updated = await registryMutator.updateGroupAccess(id: id, ownerId: ownerId, access: access)
        if !updated {
            logger.info("Registry", "Owner does not own this group.", service: .seer)
        }
        return updated
    }

    @discardableResult
    func renameGroup(id: String, ownerId: String, label: String) async -> Bool {
        await registryMutator.renameGroup(id: id, ownerId: ownerId, label: label)
    }

    @discardableResult
    func updateGroupMetadata(id: String, ownerId: String, metadata: Seer.Group.Metadata) async -> Bool {
        await registryMutator.updateGroupMetadata(id: id, ownerId: ownerId, metadata: metadata)
    }

    @discardableResult
    func updateGroup(_ group: Seer.Group, documentId: String, ownerId: String) async -> Bool {
        await registryMutator.updateGroup(group, documentId: documentId, ownerId: ownerId)
    }

    nonisolated var registry: SeerRegistry? { registryMutator.snapshot }

    nonisolated func coOwners(for documentIds: some Collection<DocumentID>) -> [DocumentID: Set<OwnerID>] {
        guard let reg = registry else { return [:] }
        return documentIds.reduce(into: [:]) { result, docId in
            var owners = Set(reg.documentOwners[docId]?.map(\.id) ?? [])
            for groupId in reg.documentGroups[docId] ?? [] {
                if let groupOwner = reg.groupOwners[groupId] {
                    owners.insert(groupOwner.id)
                }
            }
            guard owners.count > 1 else { return }
            result[docId] = owners
        }
    }
}
