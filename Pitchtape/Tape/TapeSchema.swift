import Foundation
import SwiftData

enum TapeFault: Error, Equatable, Sendable {
    case containerFailed
    case saveFailed
    case missingPeriod
    case bentRow
}

/// Role: Tape. VersionedSchema v1. Period and Call only.
enum TapeSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [PeriodRecord.self, CallRecord.self] }
}

/// Role: Tape. Migration plan from v1. Empty stages until a real move exists.
enum TapeMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [TapeSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

/// Role: Tape. Exactly one ModelContainer factory. Failure is a Result, never try!.
enum TapeChest {
    static func open(configuration: ModelConfiguration? = nil) -> Result<ModelContainer, TapeFault> {
        let resolved: ModelConfiguration
        if let configuration {
            resolved = configuration
        } else {
            switch diskConfiguration() {
            case .success(let created):
                resolved = created
            case .failure(let error):
                return .failure(error)
            }
        }
        do {
            let schema = Schema(versionedSchema: TapeSchemaV1.self)
            let container = try ModelContainer(
                for: schema,
                migrationPlan: TapeMigrationPlan.self,
                configurations: [resolved]
            )
            return .success(container)
        } catch {
            return .failure(.containerFailed)
        }
    }

    static func memory() -> Result<ModelContainer, TapeFault> {
        open(
            configuration: ModelConfiguration(
                "PitchtapeMemory",
                schema: Schema(versionedSchema: TapeSchemaV1.self),
                isStoredInMemoryOnly: true
            )
        )
    }

    static func diskConfiguration() -> Result<ModelConfiguration, TapeFault> {
        do {
            let root = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let folder = root.appendingPathComponent("Pitchtape", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            return .success(
                ModelConfiguration(
                    schema: Schema(versionedSchema: TapeSchemaV1.self),
                    url: folder.appendingPathComponent("tape.store")
                )
            )
        } catch {
            return .failure(.containerFailed)
        }
    }
}
