import Foundation
import CoreData

// MARK: - Core Data Model (programmatic)

final class ArchivedMovementStore {
    static let shared = ArchivedMovementStore()

    private let container: NSPersistentContainer

    private init() {
        let model = ArchivedMovementStore.buildModel()
        container = NSPersistentContainer(name: "BancoGYE", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error { fatalError("CoreData error: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func buildModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "ArchivedMovement"
        entity.managedObjectClassName = NSStringFromClass(ArchivedMovementEntity.self)

        func attr(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = type
            a.isOptional = true
            return a
        }

        entity.properties = [
            attr("id", .UUIDAttributeType),
            attr("reference", .stringAttributeType),
            attr("descriptionText", .stringAttributeType),
            attr("contactName", .stringAttributeType),
            attr("amount", .decimalAttributeType),
            attr("type", .stringAttributeType),
            attr("status", .stringAttributeType),
            attr("date", .dateAttributeType),
            attr("notes", .stringAttributeType),
            attr("archivedAt", .dateAttributeType)
        ]
        model.entities = [entity]
        return model
    }

    var context: NSManagedObjectContext { container.viewContext }

    func archive(_ movement: Movement) {
        let ctx = container.viewContext
        if fetchEntity(id: movement.id, in: ctx) != nil { return }

        let entity = ArchivedMovementEntity(context: ctx)
        entity.id = movement.id
        entity.reference = movement.reference
        entity.descriptionText = movement.description
        entity.contactName = movement.contactName
        entity.amount = movement.amount as NSDecimalNumber
        entity.type = movement.type.rawValue
        entity.status = movement.status.rawValue
        entity.date = movement.date
        entity.notes = movement.notes
        entity.archivedAt = Date()

        try? ctx.save()
    }

    func unarchive(id: UUID) {
        let ctx = container.viewContext
        guard let entity = fetchEntity(id: id, in: ctx) else { return }
        ctx.delete(entity)
        try? ctx.save()
    }

    func isArchived(id: UUID) -> Bool {
        fetchEntity(id: id, in: container.viewContext) != nil
    }

    func fetchAllArchived() -> [Movement] {
        let request = NSFetchRequest<ArchivedMovementEntity>(entityName: "ArchivedMovement")
        request.sortDescriptors = [NSSortDescriptor(key: "archivedAt", ascending: false)]
        let entities = (try? container.viewContext.fetch(request)) ?? []
        return entities.compactMap { $0.toMovement() }
    }

    private func fetchEntity(id: UUID, in ctx: NSManagedObjectContext) -> ArchivedMovementEntity? {
        let request = NSFetchRequest<ArchivedMovementEntity>(entityName: "ArchivedMovement")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? ctx.fetch(request).first
    }
}

// MARK: - NSManagedObject subclass

@objc(ArchivedMovementEntity)
final class ArchivedMovementEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var reference: String?
    @NSManaged var descriptionText: String?
    @NSManaged var contactName: String?
    @NSManaged var amount: NSDecimalNumber?
    @NSManaged var type: String?
    @NSManaged var status: String?
    @NSManaged var date: Date?
    @NSManaged var notes: String?
    @NSManaged var archivedAt: Date?

    func toMovement() -> Movement? {
        guard let id, let reference, let description = descriptionText,
              let contactName, let amount, let type, let status, let date else { return nil }
        return Movement(
            id: id,
            reference: reference,
            description: description,
            contactName: contactName,
            amount: amount as Decimal,
            type: MovementType(rawValue: type) ?? .transfer,
            status: MovementStatus(rawValue: status) ?? .completed,
            date: date,
            notes: notes
        )
    }
}
