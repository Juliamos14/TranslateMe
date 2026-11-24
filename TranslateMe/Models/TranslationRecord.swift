//
//  TranslationRecord.swift
//  TranslateMe
//
//  One saved translation, stored as a document in the Firestore
//  "translations" collection.
//

import Foundation
import FirebaseFirestore

struct TranslationRecord: Identifiable {
    let id: String          // Firestore document id
    let sourceText: String
    let translatedText: String
    let sourceCode: String
    let targetCode: String
    let createdAt: Date

    var sourceLanguage: Language { Language.named(sourceCode) }
    var targetLanguage: Language { Language.named(targetCode) }

    /// The fields saved to Firestore.
    static func data(sourceText: String, translatedText: String,
                     source: Language, target: Language) -> [String: Any] {
        [
            "sourceText": sourceText,
            "translatedText": translatedText,
            "sourceLanguage": source.code,
            "targetLanguage": target.code,
            "createdAt": Timestamp(date: Date()),
        ]
    }

    /// Reads a record back from a Firestore document. Returns nil if a field is missing.
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard
            let sourceText = data["sourceText"] as? String,
            let translatedText = data["translatedText"] as? String,
            let sourceCode = data["sourceLanguage"] as? String,
            let targetCode = data["targetLanguage"] as? String
        else { return nil }

        self.id = document.documentID
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceCode = sourceCode
        self.targetCode = targetCode
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}
