//
//  Seer+HNSW.swift
//  seer-server
//
//  Created by Ritesh Pakala on 3/13/26.
//

import Foundation

extension Seer {
    // MARK: - Startup

    func initializeHNSW() async {
        await self.deduplicateGlobalHNSW()
        await self.compactGlobalHNSW()
    }

    // MARK: - Dedup

    @discardableResult
    func deduplicateGlobalHNSW() async -> Int {
        let removed = await tableMutator.deduplicateCrossShardNodes()
        if removed > 0 {
            logger.info(
                "HNSW Dedup",
                "⚜️ Global — removed \(removed) cross-shard duplicate document(s)",
                service: .seer
            )
        }
        return removed
    }

    // MARK: - Global HNSW

    func compactGlobalHNSW() async {
        let result = await tableMutator.compact()
        let didChange = result.removedNodes > 0 || result.demotedEmptyHubs > 0
        guard didChange else {
            logger.debug(
                "HNSW Compact",
                "⚜️ Global graph is clean (nodes=\(result.afterNodes) maxLevel=\(result.afterMaxLevel))",
                service: .seer
            )
            return
        }
        logger.info(
            "HNSW Compact",
            "⚜️ Global — compacted \(result.removedNodes) deleted node(s) (\(result.removedHubs) hub(s)), demoted \(result.demotedEmptyHubs) empty hub(s) — \(result.beforeNodes) → \(result.afterNodes) nodes, maxLevel=\(result.afterMaxLevel)",
            service: .seer
        )
    }

    // MARK: - Node removal

    func removeNode(partitionId: String, ownerId: String) async {
        guard let table = self.table else {
            logger.warning(
                "⚠️ Partition \(partitionId) not found in HNSW — nothing to remove",
                service: .seer
            )
            return
        }

        var documentId: String?
        for shard in table.shards {
            if let nodeIndex = shard.partitionLookup[partitionId] {
                documentId = shard.nodes[nodeIndex].documentId
                break
            }
        }

        guard let documentId else {
            logger.warning(
                "⚠️ Partition \(partitionId) not found in HNSW — nothing to remove",
                service: .seer
            )
            return
        }

        logger.info(
            "Remove Node",
            "⚜️ Removing node for partition \(partitionId) and document \(documentId)",
            service: .seer
        )

        await remove(documentId: documentId, ownerId: ownerId)

        await compactGlobalHNSW()
    }
}

