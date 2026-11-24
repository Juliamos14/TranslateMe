//
//  ContentView.swift
//  TranslateMe
//
//  The TranslateMe home page: language pickers, a text field to type in,
//  a Translate button, the translation (empty at first), and the saved
//  history below, all in one scrolling list.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var translator = TranslatorViewModel()
    @StateObject private var history = HistoryStore()

    @FocusState private var isInputFocused: Bool
    @State private var showClearConfirmation = false
    @State private var showCopied = false

    var body: some View {
        NavigationStack {
            List {
                translatorSection
                historySection
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("TranslateMe")
            .background(backgroundGradient)
            .scrollContentBackground(.hidden)
            .onAppear { history.startListening() }
            .onDisappear { history.stopListening() }
            .alert("Translation", isPresented: errorBinding(for: $translator.errorMessage)) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(translator.errorMessage ?? "")
            }
            .alert("History", isPresented: errorBinding(for: $history.errorMessage)) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(history.errorMessage ?? "")
            }
            .confirmationDialog(
                "Erase all translation history?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Erase History", role: .destructive) {
                    Task { await history.clearAll() }
                }
            }
        }
        .tint(.teal)
    }

    // MARK: Translator

    private var translatorSection: some View {
        Section {
            languageBar

            // Upper field: what to translate
            ZStack(alignment: .topTrailing) {
                TextField("Enter a word, phrase, or sentence", text: $translator.inputText, axis: .vertical)
                    .lineLimit(3...6)
                    .focused($isInputFocused)
                    .padding(.trailing, 24)
                if !translator.inputText.isEmpty {
                    Button {
                        translator.clearInput()
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear text")
                }
            }
            .padding(.vertical, 6)

            translateButton

            // Lower field: the translation (empty until Translate is tapped)
            HStack(alignment: .top) {
                Text(translator.translatedText.isEmpty ? "Translation" : translator.translatedText)
                    .foregroundStyle(translator.translatedText.isEmpty ? .secondary : .primary)
                    .font(translator.translatedText.isEmpty ? .body : .title3.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
                    .textSelection(.enabled)
                if !translator.translatedText.isEmpty {
                    Button {
                        UIPasteboard.general.string = translator.translatedText
                        withAnimation { showCopied = true }
                        Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            withAnimation { showCopied = false }
                        }
                    } label: {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.teal)
                    .accessibilityLabel("Copy translation")
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var languageBar: some View {
        HStack {
            languageMenu(selection: $translator.source)
            Spacer()
            Button {
                translator.swapLanguages()
            } label: {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.teal)
            .accessibilityLabel("Swap languages")
            Spacer()
            languageMenu(selection: $translator.target)
        }
    }

    private func languageMenu(selection: Binding<Language>) -> some View {
        Menu {
            Picker("Language", selection: selection) {
                ForEach(Language.all) { language in
                    Text(language.label).tag(language)
                }
            }
        } label: {
            Text(selection.wrappedValue.label)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.teal.opacity(0.15), in: Capsule())
        }
    }

    private var translateButton: some View {
        Button {
            isInputFocused = false
            Task { await translator.translate(saveTo: history) }
        } label: {
            HStack(spacing: 8) {
                if translator.isTranslating {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "globe")
                }
                Text(translator.isTranslating ? "Translating…" : "Translate")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [.teal, .blue], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .opacity(translator.canTranslate || translator.isTranslating ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!translator.canTranslate)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    // MARK: History

    private var historySection: some View {
        Section {
            if !FirebaseSetup.isConfigured {
                Label {
                    Text("History needs Firebase. Add GoogleService-Info.plist to the TranslateMe folder in Xcode, then run the app again.")
                        .font(.footnote)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                }
            } else if history.records.isEmpty {
                Text("Your translations will appear here.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(history.records) { record in
                    Button {
                        translator.load(record)
                    } label: {
                        HistoryRow(record: record)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    for index in offsets {
                        history.delete(history.records[index])
                    }
                }
            }
        } header: {
            HStack {
                Text("History")
                Spacer()
                if !history.records.isEmpty {
                    Button("Erase All", role: .destructive) {
                        showClearConfirmation = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .textCase(nil)
                }
            }
        }
    }

    // MARK: Helpers

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.teal.opacity(0.18), Color(.systemGroupedBackground)],
            startPoint: .top,
            endPoint: .center
        )
        .ignoresSafeArea()
    }

    /// Turns an optional error message into a Bool binding for `.alert`.
    private func errorBinding(for message: Binding<String?>) -> Binding<Bool> {
        Binding(
            get: { message.wrappedValue != nil },
            set: { if !$0 { message.wrappedValue = nil } }
        )
    }
}

/// One saved translation: languages, original text, and translation.
struct HistoryRow: View {
    let record: TranslationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(record.sourceLanguage.flag) → \(record.targetLanguage.flag)  ·  \(record.createdAt.formatted(.relative(presentation: .named)))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(record.sourceText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text(record.translatedText)
                .font(.body.weight(.semibold))
                .lineLimit(3)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

#Preview {
    ContentView()
}
