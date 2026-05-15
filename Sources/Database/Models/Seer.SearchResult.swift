import Foundation

extension Seer {
    struct SearchResult {
        var data: [PartitionSearchResult]
        var adjustments: [SinatraAdjustment]
        var shardStats: [SearchShardStat]

        var partitionWithScores: [(score: Float, partition: Seer.Partition)] {
            data.flatMap { zip($0.scores, $0.partitions) }
        }

        var partitions: [Seer.Partition] {
            data.flatMap { $0.partitions }
        }

        var asDocumentReference: [Seer.DocumentReference] {
            partitions.map {
                .init(id: $0.documentId, partitionId: $0.id, ownerId: $0.ownerId)
            }
        }
    }

    struct SearchChatResult {
        var context: [String]
        var adjustments: [SinatraAdjustment]
        var references: [Seer.DocumentReference]
        var partitions: [Seer.Partition]
        var shardStats: [SearchShardStat]

        init(
            context: [String],
            adjustments: [SinatraAdjustment],
            references: [Seer.DocumentReference],
            partitions: [Seer.Partition] = [],
            shardStats: [SearchShardStat] = []
        ) {
            self.context = context
            self.adjustments = adjustments
            self.references = references
            self.partitions = partitions
            self.shardStats = shardStats
        }
    }
}
