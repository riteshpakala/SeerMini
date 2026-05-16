import ArgumentParser
import Foundation
import Logging
import Vapor

func configureRoutes(_ app: Application, _ seer: Seer, embeddingModelProvider: any EmbeddingProviding) async throws {
    registerHealthRoute(app)
    let protected = app.grouped(Middleware())
    registerSearchRoute(protected, seer, embeddingModelProvider: embeddingModelProvider)
    registerBatchEmbeddingsRoute(protected, seer, embeddingModelProvider: embeddingModelProvider)
    registerLibraryRoute(protected, seer)
}

// Pass-through middleware — no auth in SeerMini; ownerId comes from the request body.
struct Middleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        try await next.respond(to: request)
    }
}

@main
struct SeerMiniServer: AsyncParsableCommand {
    @ArgumentParser.Option(name: .long, help: "Host address.")
    var host: String = AppConstants.defaultHost

    @ArgumentParser.Option(name: .long, help: "Port number.")
    var port: Int = AppConstants.defaultPort

    #if canImport(MLX)
    @ArgumentParser.Flag(name: .long, help: "Use on-device MLX embedding model instead of Mistral API.")
    var useMLX: Bool = false

    @ArgumentParser.Option(name: .long, help: "MLX Hub model ID for on-device embeddings.")
    var mlxModel: String = "mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ"
    #endif

    enum CodingKeys: CodingKey {
        case host, port
        #if canImport(MLX)
        case useMLX, mlxModel
        #endif
    }

    @MainActor
    func run() async throws {
        let app = try await setupApplication()
        app.logger.logLevel = .debug

        let seer = Seer()
        let embeddingModelProvider: any EmbeddingProviding = makeEmbeddingProvider(logger: app.logger)

        app.routes.defaultMaxBodySize = "100mb"
        configureCORS(app)
        try await configureRoutes(app, seer, embeddingModelProvider: embeddingModelProvider)

        do {
            try await startServer(app)
        } catch {
            await seer.shutdown()
            try? await app.asyncShutdown()
            throw error
        }
        await seer.shutdown()
        try? await app.asyncShutdown()
    }

    private func makeEmbeddingProvider(logger: Logger) -> any EmbeddingProviding {
        #if canImport(MLX)
        if useMLX {
            logger.info("Embedding backend: MLX (\(mlxModel))")
            return MLXEmbeddingModelProvider(modelId: mlxModel)
        }
        #endif
        logger.info("Embedding backend: Mistral API (mistral-embed)")
        return EmbeddingModelProvider(logger: logger)
    }

    private func setupApplication() async throws -> Application {
        var env = Environment(name: "production", arguments: ["vapor"])
        try LoggingSystem.bootstrap(from: &env)
        return try await Application.make(env)
    }

    private func configureCORS(_ app: Application) {
        let cors = CORSMiddleware.Configuration(
            allowedOrigin: .all,
            allowedMethods: [.GET, .POST, .OPTIONS],
            allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
        )
        app.middleware.use(CORSMiddleware(configuration: cors))
    }

    private func startServer(_ app: Application) async throws {
        app.http.server.configuration.hostname = host
        app.http.server.configuration.port = port
        let logger = SeerLogger(app.logger)
        logger.info("Startup", "SeerMini starting on http://\(host):\(port)", service: .startup)
        try await app.execute()
    }
}

func registerHealthRoute(_ app: RoutesBuilder) {
    app.get("health") { _ in ["status": "ok"] }
}
