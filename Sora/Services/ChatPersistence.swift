//
//  ChatPersistence.swift
//  Sora
//
//  Локальное хранение истории чатов (Core Data).
//  Сессия создаётся только после первого сообщения.
//

import CoreData
import UIKit

// MARK: - Model (programmatic)

private func makeChatModel() -> NSManagedObjectModel {
    let model = NSManagedObjectModel()
    
    let sessionEntity = NSEntityDescription()
    sessionEntity.name = "ChatSessionEntity"
    sessionEntity.managedObjectClassName = "ChatSessionEntity"
    
    let sessionId = NSAttributeDescription()
    sessionId.name = "id"
    sessionId.attributeType = .UUIDAttributeType
    sessionId.isOptional = false
    let sessionCreatedAt = NSAttributeDescription()
    sessionCreatedAt.name = "createdAt"
    sessionCreatedAt.attributeType = .dateAttributeType
    sessionCreatedAt.isOptional = false
    let sessionTitle = NSAttributeDescription()
    sessionTitle.name = "title"
    sessionTitle.attributeType = .stringAttributeType
    sessionTitle.isOptional = false
    let sessionCustomTitle = NSAttributeDescription()
    sessionCustomTitle.name = "customTitle"
    sessionCustomTitle.attributeType = .stringAttributeType
    sessionCustomTitle.isOptional = true
    
    sessionEntity.properties = [sessionId, sessionCreatedAt, sessionTitle, sessionCustomTitle]
    
    let messageEntity = NSEntityDescription()
    messageEntity.name = "MessageEntity"
    messageEntity.managedObjectClassName = "MessageEntity"
    
    let msgId = NSAttributeDescription()
    msgId.name = "id"
    msgId.attributeType = .UUIDAttributeType
    msgId.isOptional = false
    let msgChatId = NSAttributeDescription()
    msgChatId.name = "chatId"
    msgChatId.attributeType = .UUIDAttributeType
    msgChatId.isOptional = false
    let msgRole = NSAttributeDescription()
    msgRole.name = "role"
    msgRole.attributeType = .stringAttributeType
    msgRole.isOptional = false
    let msgContent = NSAttributeDescription()
    msgContent.name = "content"
    msgContent.attributeType = .stringAttributeType
    msgContent.isOptional = true
    let msgImageData = NSAttributeDescription()
    msgImageData.name = "imageData"
    msgImageData.attributeType = .binaryDataAttributeType
    msgImageData.isOptional = true
    let msgImageURL = NSAttributeDescription()
    msgImageURL.name = "imageURL"
    msgImageURL.attributeType = .stringAttributeType
    msgImageURL.isOptional = true
    let msgCreatedAt = NSAttributeDescription()
    msgCreatedAt.name = "createdAt"
    msgCreatedAt.attributeType = .dateAttributeType
    msgCreatedAt.isOptional = false
    let msgOrder = NSAttributeDescription()
    msgOrder.name = "order"
    msgOrder.attributeType = .integer64AttributeType
    msgOrder.isOptional = false
    msgOrder.defaultValue = 0
    
    messageEntity.properties = [msgId, msgChatId, msgRole, msgContent, msgImageData, msgImageURL, msgCreatedAt, msgOrder]
    
    let rel = NSRelationshipDescription()
    rel.name = "messages"
    rel.destinationEntity = messageEntity
    rel.minCount = 0
    rel.maxCount = 0
    rel.deleteRule = .cascadeDeleteRule
    let inv = NSRelationshipDescription()
    inv.name = "session"
    inv.destinationEntity = sessionEntity
    inv.minCount = 1
    inv.maxCount = 1
    inv.deleteRule = .nullifyDeleteRule
    rel.inverseRelationship = inv
    inv.inverseRelationship = rel
    
    sessionEntity.properties.append(rel)
    messageEntity.properties.append(inv)
    
    model.entities = [sessionEntity, messageEntity]
    return model
}

// UUID in Core Data: we'll use Transformable or String to avoid version issues. Actually .UUIDAttributeType exists in iOS 11+. Let me use String for id and chatId for maximum compatibility.
// Re-checking: the above uses UUIDAttributeType. If the project targets iOS 17 we're fine. Let me keep it and if needed we can switch to String. Actually I'll use String for id/chatiId so we don't depend on UUID attribute type (which might not be in all OS versions).
private func makeChatModelStringIds() -> NSManagedObjectModel {
    let model = NSManagedObjectModel()
    
    let sessionEntity = NSEntityDescription()
    sessionEntity.name = "ChatSessionEntity"
    sessionEntity.managedObjectClassName = "ChatSessionEntity"
    
    let sessionId = NSAttributeDescription()
    sessionId.name = "id"
    sessionId.attributeType = .stringAttributeType
    sessionId.isOptional = false
    let sessionCreatedAt = NSAttributeDescription()
    sessionCreatedAt.name = "createdAt"
    sessionCreatedAt.attributeType = .dateAttributeType
    sessionCreatedAt.isOptional = false
    let sessionTitle = NSAttributeDescription()
    sessionTitle.name = "title"
    sessionTitle.attributeType = .stringAttributeType
    sessionTitle.isOptional = false
    let sessionCustomTitle = NSAttributeDescription()
    sessionCustomTitle.name = "customTitle"
    sessionCustomTitle.attributeType = .stringAttributeType
    sessionCustomTitle.isOptional = true
    
    sessionEntity.properties = [sessionId, sessionCreatedAt, sessionTitle, sessionCustomTitle]
    
    let messageEntity = NSEntityDescription()
    messageEntity.name = "MessageEntity"
    messageEntity.managedObjectClassName = "MessageEntity"
    
    let msgId = NSAttributeDescription()
    msgId.name = "id"
    msgId.attributeType = .stringAttributeType
    msgId.isOptional = false
    let msgChatId = NSAttributeDescription()
    msgChatId.name = "chatId"
    msgChatId.attributeType = .stringAttributeType
    msgChatId.isOptional = false
    let msgRole = NSAttributeDescription()
    msgRole.name = "role"
    msgRole.attributeType = .stringAttributeType
    msgRole.isOptional = false
    let msgContent = NSAttributeDescription()
    msgContent.name = "content"
    msgContent.attributeType = .stringAttributeType
    msgContent.isOptional = true
    let msgImageData = NSAttributeDescription()
    msgImageData.name = "imageData"
    msgImageData.attributeType = .binaryDataAttributeType
    msgImageData.isOptional = true
    let msgImageURL = NSAttributeDescription()
    msgImageURL.name = "imageURL"
    msgImageURL.attributeType = .stringAttributeType
    msgImageURL.isOptional = true
    let msgCreatedAt = NSAttributeDescription()
    msgCreatedAt.name = "createdAt"
    msgCreatedAt.attributeType = .dateAttributeType
    msgCreatedAt.isOptional = false
    let msgOrder = NSAttributeDescription()
    msgOrder.name = "order"
    msgOrder.attributeType = .integer64AttributeType
    msgOrder.isOptional = false
    msgOrder.defaultValue = 0
    
    messageEntity.properties = [msgId, msgChatId, msgRole, msgContent, msgImageData, msgImageURL, msgCreatedAt, msgOrder]
    
    let rel = NSRelationshipDescription()
    rel.name = "messages"
    rel.destinationEntity = messageEntity
    rel.minCount = 0
    rel.maxCount = 0
    rel.deleteRule = .cascadeDeleteRule
    let inv = NSRelationshipDescription()
    inv.name = "session"
    inv.destinationEntity = sessionEntity
    inv.minCount = 1
    inv.maxCount = 1
    inv.deleteRule = .nullifyDeleteRule
    rel.inverseRelationship = inv
    inv.inverseRelationship = rel
    
    sessionEntity.properties.append(rel)
    messageEntity.properties.append(inv)
    
    model.entities = [sessionEntity, messageEntity]
    return model
}

// MARK: - Container

final class ChatPersistence {
    static let shared = ChatPersistence()
    
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext { container.viewContext }
    
    private init() {
        let model = makeChatModelStringIds()
        container = NSPersistentContainer(name: "ChatModel", managedObjectModel: model)
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: Self.storeURL)]
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data load error: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    private static var storeURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("ChatModel.sqlite")
    }
    
    func save() {
        let ctx = viewContext
        guard ctx.hasChanges else { return }
        try? ctx.save()
    }
}

// MARK: - NSManagedObject subclasses (must be in same module as model)

@objc(ChatSessionEntity)
public class ChatSessionEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var createdAt: Date
    @NSManaged public var title: String
    @NSManaged public var customTitle: String?
    @NSManaged public var messages: NSSet?
}

@objc(MessageEntity)
public class MessageEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var chatId: String
    @NSManaged public var role: String
    @NSManaged public var content: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var imageURL: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var order: Int64
    @NSManaged public var session: ChatSessionEntity?
}

// MARK: - ChatStore (UI-facing API)

/// Элемент списка для HistoryView
struct ChatSessionItem: Identifiable {
    let id: UUID
    let title: String
    let createdAt: Date
}

final class ChatStore: ObservableObject {
    static let shared = ChatStore()
    private let persistence = ChatPersistence.shared
    
    private init() {}
    
    /// Все сессии с хотя бы одним сообщением (для HistoryView). Сортировка по createdAt по убыванию.
    func fetchAllSessions() -> [ChatSessionItem] {
        let ctx = persistence.viewContext
        let req = NSFetchRequest<ChatSessionEntity>(entityName: "ChatSessionEntity")
        req.predicate = NSPredicate(format: "messages.@count > 0")
        req.sortDescriptors = [NSSortDescriptor(keyPath: \ChatSessionEntity.createdAt, ascending: false)]
        guard let list = try? ctx.fetch(req) else { return [] }
        return list.compactMap { e in
            guard let uuid = UUID(uuidString: e.id) else { return nil }
            return ChatSessionItem(id: uuid, title: e.customTitle?.isEmpty == false ? e.customTitle! : e.title, createdAt: e.createdAt)
        }
    }
    
    /// Загрузить сообщения сессии в UI-модель [Message]
    func fetchMessages(sessionId: UUID) -> [Message] {
        let ctx = persistence.viewContext
        let req = NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
        req.predicate = NSPredicate(format: "chatId == %@", sessionId.uuidString)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \MessageEntity.order, ascending: true)]
        guard let list = try? ctx.fetch(req) else { return [] }
        return list.compactMap { entityToMessage($0) }
    }
    
    /// Создать сессию после первого сообщения. Возвращает id сессии. Title — первое предложение/обрезанный текст (до 60 символов).
    func createSession(firstMessageText: String, customTitle: String? = nil) -> UUID {
        let ctx = persistence.viewContext
        let session = ChatSessionEntity(context: ctx)
        let id = UUID()
        session.id = id.uuidString
        session.createdAt = Date()
        session.customTitle = customTitle
        let title = titleFromFirstMessage(firstMessageText)
        session.title = title
        persistence.save()
        return id
    }
    
    /// Добавить сообщение в существующую сессию (outgoing или incoming).
    func addMessage(sessionId: UUID, message: Message, order: Int64) {
        let ctx = persistence.viewContext
        let req = NSFetchRequest<ChatSessionEntity>(entityName: "ChatSessionEntity")
        req.predicate = NSPredicate(format: "id == %@", sessionId.uuidString)
        req.fetchLimit = 1
        guard let session = try? ctx.fetch(req).first else { return }
        let ent = MessageEntity(context: ctx)
        ent.id = message.id.uuidString
        ent.chatId = sessionId.uuidString
        ent.role = message.isIncoming ? "assistant" : "user"
        ent.content = message.text.isEmpty ? nil : message.text
        ent.createdAt = Date()
        ent.order = order
        if let img = message.image, let data = img.jpegData(compressionQuality: 0.85) {
            ent.imageData = data
        }
        if let url = message.videoURL {
            ent.imageURL = url.absoluteString
        }
        ent.session = session
        persistence.save()
    }
    
    /// Сохранить полный список сообщений сессии (перезаписывает порядок по индексу).
    func saveMessages(sessionId: UUID, messages: [Message]) {
        let ctx = persistence.viewContext
        let req = NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
        req.predicate = NSPredicate(format: "chatId == %@", sessionId.uuidString)
        let existing = (try? ctx.fetch(req)) ?? []
        existing.forEach { ctx.delete($0) }
        for (idx, msg) in messages.enumerated() {
            let ent = MessageEntity(context: ctx)
            ent.id = msg.id.uuidString
            ent.chatId = sessionId.uuidString
            ent.role = msg.isIncoming ? "assistant" : "user"
            ent.content = msg.text.isEmpty ? nil : msg.text
            ent.createdAt = Date()
            ent.order = Int64(idx)
            if let img = msg.image, let data = img.jpegData(compressionQuality: 0.85) {
                ent.imageData = data
            }
            if let url = msg.videoURL {
                ent.imageURL = url.absoluteString
            }
            let sessionReq = NSFetchRequest<ChatSessionEntity>(entityName: "ChatSessionEntity")
            sessionReq.predicate = NSPredicate(format: "id == %@", sessionId.uuidString)
            sessionReq.fetchLimit = 1
            if let sess = try? ctx.fetch(sessionReq).first {
                ent.session = sess
            }
        }
        persistence.save()
    }
    
    func deleteSession(sessionId: UUID) {
        let ctx = persistence.viewContext
        let req = NSFetchRequest<ChatSessionEntity>(entityName: "ChatSessionEntity")
        req.predicate = NSPredicate(format: "id == %@", sessionId.uuidString)
        req.fetchLimit = 1
        guard let session = try? ctx.fetch(req).first else { return }
        ctx.delete(session)
        persistence.save()
    }
    
    func renameSession(sessionId: UUID, customTitle: String) {
        let ctx = persistence.viewContext
        let req = NSFetchRequest<ChatSessionEntity>(entityName: "ChatSessionEntity")
        req.predicate = NSPredicate(format: "id == %@", sessionId.uuidString)
        req.fetchLimit = 1
        guard let session = try? ctx.fetch(req).first else { return }
        session.customTitle = customTitle
        persistence.save()
    }
    
    private func entityToMessage(_ ent: MessageEntity) -> Message? {
        guard let id = UUID(uuidString: ent.id) else { return nil }
        var image: UIImage?
        if let data = ent.imageData {
            image = UIImage(data: data)
        }
        var videoURL: URL?
        if let s = ent.imageURL, let url = URL(string: s) {
            videoURL = url
        }
        let isIncoming = ent.role == "assistant"
        return Message(id: id, text: ent.content ?? "", image: image, videoURL: videoURL, isIncoming: isIncoming)
    }
    
    private func titleFromFirstMessage(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        if trimmed.isEmpty { return "New chat" }
        if let end = trimmed.firstIndex(of: ".").map({ trimmed.index(after: $0) }),
           end <= trimmed.endIndex {
            let segment = String(trimmed[..<end]).trimmingCharacters(in: .whitespaces)
            if !segment.isEmpty { return String(segment.prefix(60)) }
        }
        return String(trimmed.prefix(60))
    }
}
