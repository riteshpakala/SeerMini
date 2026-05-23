//
//  Fixtures.swift
//  seer-mini-tests
//

import Foundation
import Logging
@testable import seer_mini

// MARK: - Logger

extension Logger {
    static var test: Logger {
        var logger = Logger(label: "test-seer-mini")
        logger.logLevel = .critical
        return logger
    }
}

extension SeerLogger {
    static var test: SeerLogger { SeerLogger(.test) }
}

// MARK: - SeerRequest

extension SeerRequest {
    static func test(
        ownerId: String = "test-owner",
        scope: SeerRequestScope? = .personal
    ) -> SeerRequest {
        SeerRequest(ownerId: ownerId, group: nil, aggregate: nil, scope: scope, requestID: nil)
    }
}

// MARK: - Seer.Partition

extension Seer.Partition {
    static func test(
        id: String = UUID().uuidString,
        documentId: String = "test-doc",
        url: URL = URL(string: "https://example.com")!,
        embedding: [Float] = [],
        text: String = "test text here",
        ownerId: String = "test-owner"
    ) -> Seer.Partition {
        Seer.Partition(
            id: id,
            documentId: documentId,
            url: url,
            embedding: embedding,
            text: text,
            ownerId: ownerId
        )
    }
}

// MARK: - Vector Fixtures

/// Deterministic vector helpers for reproducible test cases.
/// All vectors use `dim = 32` — divisible by 16 (PartitionQuantizer.numSubvectors).
enum VectorFixtures {
    static let dim = 32

    /// All-zero vector.
    static func zeros() -> [Float] { [Float](repeating: 0, count: dim) }

    /// Unit vector along a single axis.
    static func unit(axis: Int) -> [Float] {
        var v = [Float](repeating: 0, count: dim)
        v[axis % dim] = 1.0
        return v
    }

    /// Seeded pseudo-random vector — deterministic across runs.
    static func random(seed: UInt64) -> [Float] {
        random(dim: dim, seed: seed)
    }

    /// Seeded pseudo-random vector at an explicit dimension.
    static func random(dim: Int, seed: UInt64) -> [Float] {
        var state = seed &* 6364136223846793005 &+ 1442695040888963407
        return (0..<dim).map { _ in
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Float(Int(bitPattern: UInt(state >> 33)) % 1000) / 500.0 - 1.0
        }
    }

    /// Vector very close to `center` (small perturbation).
    static func near(_ center: [Float], seed: UInt64) -> [Float] {
        var state = seed &* 6364136223846793005 &+ 1442695040888963407
        return center.map { c in
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let noise = Float(Int(bitPattern: UInt(state >> 33)) % 100) / 100000.0
            return c + noise
        }
    }

    /// L2 distance between two vectors.
    static func l2(_ a: [Float], _ b: [Float]) -> Float {
        zip(a, b).map { d in let e = d.0 - d.1; return e * e }.reduce(0, +).squareRoot()
    }
}
