//
//  HistoryStore.swift
//  TranslateMe
//
//  Saves translations to Firestore and keeps a live, newest-first list of
//  them. Uses a snapshot listener, so the list updates as soon as anything
//  is added or deleted.
//

import Foundation
import FirebaseFirestore

@MainActor
final class HistoryStore: ObservableObject {

    @Published private(set) var records: [TranslationRecord] = []
    @Published var errorMessage: String?

    private let collectionName = "translations"
    private var listener: ListenerRegistration?

    private var collection: CollectionReference? {
        guard FirebaseSetup.isConfigured else { return nil }
        return Firestore.firestore().collection(collectionName)
    }

    // MARK: Listening

    func startListening() {
        guard listener == nil, let collection else { return }
        listener = collection
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { [weak self] snapshot, error in
                let records = snapshot?.documents.compactMap(TranslationRecord.init(document:)) ?? []
                let message = error?.localizedDescription
                Task { @MainActor in
                    guard let self else { return }
                    if let message {
                        self.errorMessage = "Couldn't load history: \(message)"
                    } else {
                        self.records = records
                    }
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: Saving and deleting

    func save(sourceText: String, translatedText: String, source: Language, target: Language) {
        // Firestore saves locally right away and syncs in the background,
        // so the new item shows up in the list immediately.
        collection?.addDocument(data: TranslationRecord.data(
            sourceText: sourceText,
            translatedText: translatedText,
            source: source,
            target: target
        ))
    }

    func delete(_ record: TranslationRecord) {
        collection?.document(record.id).delete()
    }

    /// Erases the whole history in one batch, so the list clears all at once.
    func clearAll() async {
        guard let collection else { return }
        do {
            let snapshot = try await collection.getDocuments()
            let batch = Firestore.firestore().batch()
            for document in snapshot.documents {
                batch.deleteDocument(document.reference)
            }
            try await batch.commit()
        } catch {
            errorMessage = "Couldn't erase history: \(error.localizedDescription)"
        }
    }
}
