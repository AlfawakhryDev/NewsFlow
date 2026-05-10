import CoreData
import UIKit

final class CoreDataManager {
    static let shared = CoreDataManager()
    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NewsFlow")
        container.loadPersistentStores { _, error in
            if let error { fatalError("Core Data failed to load: \(error)") }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext { persistentContainer.viewContext }

    // MARK: - Save
    func saveArticle(_ article: Article) {
        guard !isSaved(article) else { return }
        let entity = SavedArticle(context: context)
        entity.title            = article.title
        entity.url              = article.url
        entity.urlToImage       = article.urlToImage
        entity.articleDescription = article.description
        entity.author           = article.author
        entity.sourceName       = article.source.name
        entity.publishedAt      = article.publishedAt
        entity.savedDate        = Date()
        saveContext()
    }

    // MARK: - Delete
    func removeArticle(_ article: Article) {
        let request: NSFetchRequest<SavedArticle> = SavedArticle.fetchRequest()
        request.predicate = NSPredicate(format: "url == %@", article.url)
        if let result = try? context.fetch(request), let entity = result.first {
            context.delete(entity)
            saveContext()
        }
    }

    // MARK: - Query
    func isSaved(_ article: Article) -> Bool {
        let request: NSFetchRequest<SavedArticle> = SavedArticle.fetchRequest()
        request.predicate = NSPredicate(format: "url == %@", article.url)
        return (try? context.count(for: request)) ?? 0 > 0
    }

    func fetchAllSaved() -> [SavedArticle] {
        let request: NSFetchRequest<SavedArticle> = SavedArticle.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Helpers
    private func saveContext() {
        guard context.hasChanges else { return }
        try? context.save()
    }
}

// MARK: - SavedArticle → Article conversion
extension SavedArticle {
    func toArticle() -> Article {
        Article(
            source:      .init(id: nil, name: sourceName ?? ""),
            author:      author,
            title:       title ?? "",
            description: articleDescription,
            url:         url ?? "",
            urlToImage:  urlToImage,
            publishedAt: publishedAt ?? "",
            content:     nil
        )
    }
}
