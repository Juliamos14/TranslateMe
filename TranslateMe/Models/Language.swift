//
//  Language.swift
//  TranslateMe
//

import Foundation

/// A language the user can translate from or to.
/// `code` is the language code MyMemory expects (e.g. "en", "es", "zh-CN").
struct Language: Identifiable, Hashable {
    let code: String
    let name: String
    let flag: String

    var id: String { code }
    var label: String { "\(flag) \(name)" }

    static let all: [Language] = [
        Language(code: "en", name: "English", flag: "🇺🇸"),
        Language(code: "es", name: "Spanish", flag: "🇪🇸"),
        Language(code: "fr", name: "French", flag: "🇫🇷"),
        Language(code: "de", name: "German", flag: "🇩🇪"),
        Language(code: "it", name: "Italian", flag: "🇮🇹"),
        Language(code: "pt", name: "Portuguese", flag: "🇵🇹"),
        Language(code: "nl", name: "Dutch", flag: "🇳🇱"),
        Language(code: "sv", name: "Swedish", flag: "🇸🇪"),
        Language(code: "ru", name: "Russian", flag: "🇷🇺"),
        Language(code: "tr", name: "Turkish", flag: "🇹🇷"),
        Language(code: "ar", name: "Arabic", flag: "🇸🇦"),
        Language(code: "hi", name: "Hindi", flag: "🇮🇳"),
        Language(code: "ja", name: "Japanese", flag: "🇯🇵"),
        Language(code: "ko", name: "Korean", flag: "🇰🇷"),
        Language(code: "zh-CN", name: "Chinese", flag: "🇨🇳"),
    ]

    static let english = all[0]
    static let spanish = all[1]

    /// Looks up a language by its code (used for history items).
    static func named(_ code: String) -> Language {
        all.first { $0.code == code } ?? Language(code: code, name: code.uppercased(), flag: "🌐")
    }
}
