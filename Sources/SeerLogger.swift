import Foundation
import Logging

struct SeerLogger {
    enum ServicesType: String {
        case sinatra     = "Sinatra"
        case seer        = "Seer"
        case embedding   = "Embedding"
        case parking     = "Parking"
        case gbtTraining = "GBT Training"
        case startup     = "Start-up"
    }

    enum SeerFlow {
        case chat
        case embed(documentId: String)
        case frank(partitionId: String)

        var serviceName: String {
            switch self {
            case .chat:  return "Flow: Chat"
            case .embed: return "Flow: Embed"
            case .frank: return "Flow: Frank"
            }
        }

        var documentId: String? {
            guard case .embed(let id) = self else { return nil }
            return id
        }

        var partitionId: String? {
            guard case .frank(let id) = self else { return nil }
            return id
        }
    }

    enum LogType: String {
        case trace, debug, info, notice, warning, error, critical
    }

    let base: Logger

    init(_ logger: Logger) { self.base = logger }

    func externallyLog(
        name: String? = nil,
        message: String,
        eventType: LogType,
        externalOnly: Bool = false,
        seer: SeerRequest? = nil,
        service: ServicesType?,
        flow: SeerFlow? = nil
    ) {
        guard let service else { return }
        let isSignificant = eventType == .info || eventType == .notice ||
                            eventType == .warning || eventType == .error || eventType == .critical
        guard isSignificant || externalOnly else { return }
        
        // This format is used for Grafana Alloy and Loki.
        var entry: [String: String] = [
            "ts": ISO8601DateFormatter().string(from: Date()),
            "level": eventType.rawValue,
            "msg": message,
            "service": service.rawValue
        ]
        if let name { entry["event"] = name }
        if let requestID = seer?.requestID, !requestID.isEmpty { entry["requestId"] = requestID }
        if let ownerId = seer?.ownerId, !ownerId.isEmpty { entry["ownerId"] = ownerId }

        if let data = try? JSONSerialization.data(withJSONObject: entry),
           let line = String(data: data, encoding: .utf8) {
            print(line)
        }

        if let flow, flow.serviceName != service.rawValue {
            var flowEntry = entry
            flowEntry["service"] = flow.serviceName
            if let documentId = flow.documentId { flowEntry["documentId"] = documentId }
            if let partitionId = flow.partitionId { flowEntry["partitionId"] = partitionId }
            if let data = try? JSONSerialization.data(withJSONObject: flowEntry),
               let line = String(data: data, encoding: .utf8) {
                print(line)
            }
        }
    }

    func trace(_ message: @autoclosure () -> Logger.Message,
               metadata: @autoclosure () -> Logger.Metadata? = nil,
               source: @autoclosure () -> String? = nil,
               service: ServicesType? = nil,
               request: SeerRequest? = nil,
               file: String = #fileID, function: String = #function, line: UInt = #line,
               then: (() -> Void)? = nil) {
        base.trace(message(), metadata: enrichedMetadata(service: service, requestID: request?.requestID, existing: metadata()), source: source(), file: file, function: function, line: line)
        then?()
    }

    func debug(_ label: String? = nil,
               _ message: @autoclosure () -> Logger.Message,
               metadata: @autoclosure () -> Logger.Metadata? = nil,
               source: @autoclosure () -> String? = nil,
               service: ServicesType? = nil,
               request: SeerRequest? = nil,
               externalOnly: Bool = false,
               flow: SeerFlow? = nil,
               file: String = #fileID, function: String = #function, line: UInt = #line,
               then: (() -> Void)? = nil) {
        if !externalOnly {
            base.debug(message(), metadata: enrichedMetadata(service: service, requestID: request?.requestID, existing: metadata()), source: source(), file: file, function: function, line: line)
        }
        externallyLog(name: label, message: message().description, eventType: .debug, externalOnly: externalOnly, seer: request, service: service, flow: flow)
        then?()
    }

    func info(_ label: String? = nil,
              _ message: @autoclosure () -> Logger.Message,
              metadata: @autoclosure () -> Logger.Metadata? = nil,
              source: @autoclosure () -> String? = nil,
              service: ServicesType? = nil,
              request: SeerRequest? = nil,
              externalOnly: Bool = false,
              flow: SeerFlow? = nil,
              file: String = #fileID, function: String = #function, line: UInt = #line,
              then: (() -> Void)? = nil) {
        if !externalOnly {
            base.info(message(), metadata: enrichedMetadata(service: service, requestID: request?.requestID, existing: metadata()), source: source(), file: file, function: function, line: line)
        }
        externallyLog(name: label, message: message().description, eventType: .info, externalOnly: externalOnly, seer: request, service: service, flow: flow)
        then?()
    }

    func notice(_ message: @autoclosure () -> Logger.Message,
                metadata: @autoclosure () -> Logger.Metadata? = nil,
                source: @autoclosure () -> String? = nil,
                service: ServicesType? = nil,
                request: SeerRequest? = nil,
                file: String = #fileID, function: String = #function, line: UInt = #line,
                then: (() -> Void)? = nil) {
        base.notice(message(), metadata: enrichedMetadata(service: service, requestID: request?.requestID, existing: metadata()), source: source(), file: file, function: function, line: line)
        then?()
    }

    func warning(_ message: @autoclosure () -> Logger.Message,
                 metadata: @autoclosure () -> Logger.Metadata? = nil,
                 source: @autoclosure () -> String? = nil,
                 service: ServicesType? = nil,
                 request: SeerRequest? = nil,
                 flow: SeerFlow? = nil,
                 file: String = #fileID, function: String = #function, line: UInt = #line,
                 then: (() -> Void)? = nil) {
        base.warning(message(), metadata: enrichedMetadata(service: service, requestID: request?.requestID, existing: metadata()), source: source(), file: file, function: function, line: line)
        externallyLog(message: message().description, eventType: .warning, seer: request, service: service, flow: flow)
        then?()
    }

    func error(_ label: String? = nil,
               _ message: @autoclosure () -> Logger.Message,
               metadata: @autoclosure () -> Logger.Metadata? = nil,
               source: @autoclosure () -> String? = nil,
               service: ServicesType? = nil,
               request: SeerRequest? = nil,
               flow: SeerFlow? = nil,
               file: String = #fileID, function: String = #function, line: UInt = #line,
               then: (() -> Void)? = nil) {
        base.error(message(), metadata: enrichedMetadata(service: service, requestID: request?.requestID, existing: metadata()), source: source(), file: file, function: function, line: line)
        externallyLog(name: label, message: message().description, eventType: .error, seer: request, service: service, flow: flow)
        then?()
    }

    func critical(_ message: @autoclosure () -> Logger.Message,
                  metadata: @autoclosure () -> Logger.Metadata? = nil,
                  source: @autoclosure () -> String? = nil,
                  service: ServicesType? = nil,
                  request: SeerRequest? = nil,
                  file: String = #fileID, function: String = #function, line: UInt = #line,
                  then: (() -> Void)? = nil) {
        base.critical(message(), metadata: enrichedMetadata(service: service, requestID: request?.requestID, existing: metadata()), source: source(), file: file, function: function, line: line)
        then?()
    }

    private func enrichedMetadata(service: ServicesType?, requestID: String?, existing: Logger.Metadata?) -> Logger.Metadata? {
        guard service != nil || requestID != nil else { return existing }
        var meta = existing ?? [:]
        if let service { meta["service"] = .string(service.rawValue) }
        if let requestID { meta["requestID"] = .string(requestID) }
        return meta
    }
}
