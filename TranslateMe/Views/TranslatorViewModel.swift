//
//  TranslatorViewModel.swift
//  TranslateMe
//

import SwiftUI

@MainActor
final class TranslatorViewModel: ObservableObject {

    @Published var inputText = ""
    @Published private(set) var translatedText = ""
    @Published var source = Language.english
    @Published var target = Language.spanish
    @Published private(set) var isTranslating = false
    @Published var errorMessage: String?

    var canTranslate: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTranslating
    }

    /// Translates the top field into the bottom field, then saves it to history.
    func translate(saveTo history: HistoryStore) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        isTranslating = true
        defer { isTranslating = false }

        do {
            let result = try await MyMemoryAPI.translate(text, from: source, to: target)
            withAnimation { translatedText = result }
            history.save(sourceText: text, translatedText: result, source: source, target: target)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Swaps the languages. If there's a translation, it moves up so it can be translated back.
    func swapLanguages() {
        withAnimation {
            (source, target) = (target, source)
            if !translatedText.isEmpty {
                inputText = translatedText
                translatedText = ""
            }
        }
    }

    /// Puts a history item back into the translator.
    func load(_ record: TranslationRecord) {
        withAnimation {
            source = record.sourceLanguage
            target = record.targetLanguage
            inputText = record.sourceText
            translatedText = record.translatedText
        }
    }

    func clearInput() {
        withAnimation {
            inputText = ""
            translatedText = ""
        }
    }
}
