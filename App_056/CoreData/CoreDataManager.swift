import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    let persistentContainer: NSPersistentContainer

    private init() {
        persistentContainer = NSPersistentContainer(name: "PresetCache")
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("❌ Error loading Core Data: \(error)")
            }
        }
    }

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext() {
        do {
            try context.save()
        } catch {
            print("❌ Error save in Core Data: \(error.localizedDescription)")
        }
    }
}
