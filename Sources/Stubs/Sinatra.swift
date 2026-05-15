import Foundation
import Logging

/// Minimal Sinatra stub for SeerMini — all methods return identity (no adjustment).
/// The full GBT/SVM ranking engine is not included; distances pass through unchanged.
class Sinatra {
    internal let logger: SeerLogger

    static var sentimentContextLimit: Int = 4
    static let maxParkedEntries: Int = 30

    init(logger: Logger) {
        self.logger = SeerLogger(logger)
    }

    var registry: SinatraRegistry? { nil }

    func infer(
        _ inference: SinatraInference,
        registry: SinatraRegistry?,
        documentStats: [DocumentID: Seer.DocumentStats] = [:],
        request: SeerRequest
    ) -> SinatraInference.Result {
        .unadjusted(distance: inference.distance)
    }

    func inferTagThreshold(
        documentId: DocumentID,
        owner: SeerRegistry.Owner,
        registry: SinatraRegistry?,
        documentStats: [DocumentID: Seer.DocumentStats]
    ) -> Float {
        1.0 - PartitionIndex.tagSimilarityThreshold
    }

    // Parking data is used for Self-RLHF. Not featured in the Mini.
    func park(
        data: [(score: Float, partition: Seer.Partition)],
        forQuery: [Float],
        request: SeerRequest
    ) {}

    func parkIndices(
        data: [(documentId: DocumentID, tagDistance: Float?, wasIncluded: Bool)],
        request: SeerRequest
    ) {}
}

/// Empty stub — SinatraRegistry is passed to Sinatra methods but never inspected
/// since all stub methods return immediately without reading it.
struct SinatraRegistry {}
