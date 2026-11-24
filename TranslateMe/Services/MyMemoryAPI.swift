//
//  MyMemoryAPI.swift
//  TranslateMe
//
//  Translates text with the MyMemory API:
//  https://api.mymemory.translated.net/get?q=Hello&langpair=en|es
//

import Foundation

enum TranslationError: LocalizedError {
    case emptyText
    case textTooLong
    case dailyLimitReached
    case server(String)

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "Type a word, phrase, or sentence to translate."
        case .textTooLong:
            return "That text is too long. MyMemory translates up to 500 characters at a time."
        case .dailyLimitReached:
            return "The free daily translation limit has been reached. Please try again tomorrow."
        case .server(let message):
            return message
        }
    }
}

enum MyMemoryAPI {

    /// MyMemory accepts up to 500 bytes of text per request.
    static let maxBytes = 500

    static func translate(_ text: String, from source: Language, to target: Language) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TranslationError.emptyText }
        guard trimmed.utf8.count <= maxBytes else { throw TranslationError.textTooLong }

        // URLComponents handles the URL-encoding of spaces and special characters.
        var components = URLComponents(string: "https://api.mymemory.translated.net/get")!
        components.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "langpair", value: "\(source.code)|\(target.code)"),
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(MyMemoryResponse.self, from: data)
        let translated = response.responseData.translatedText

        // A "successful" response can actually be a usage warning.
        if response.responseStatus == 429 || translated.uppercased().hasPrefix("MYMEMORY WARNING") {
            throw TranslationError.dailyLimitReached
        }
        guard response.responseStatus == 200 else {
            throw TranslationError.server(response.responseDetails ?? "Translation failed. Please try again.")
        }
        return translated.decodingHTMLEntities
    }
}

// MARK: - JSON model

private struct MyMemoryResponse: Decodable {
    struct ResponseData: Decodable {
        let translatedText: String
    }

    let responseData: ResponseData
    let responseStatus: Int
    let responseDetails: String?

    enum CodingKeys: String, CodingKey {
        case responseData, responseStatus, responseDetails
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        responseData = try container.decode(ResponseData.self, forKey: .responseData)
        // MyMemory sometimes sends the status as a number (200) and sometimes as text ("403").
        if let number = try? container.decode(Int.self, forKey: .responseStatus) {
            responseStatus = number
        } else if let text = try? container.decode(String.self, forKey: .responseStatus) {
            responseStatus = Int(text) ?? 0
        } else {
            responseStatus = 0
        }
        responseDetails = try? container.decode(String.self, forKey: .responseDetails)
    }
}

// MARK: - HTML entities

private extension String {
    /// Converts codes like `&#39;`, `&quot;` and `&amp;` back into normal characters.
    var decodingHTMLEntities: String {
        var result = self
        let named = ["&quot;": "\"", "&apos;": "'", "&lt;": "<", "&gt;": ">", "&nbsp;": " "]
        for (entity, character) in named {
            result = result.replacingOccurrences(of: entity, with: character)
        }

        // Numeric codes, e.g. &#39; → '
        while let range = result.range(of: "&#[0-9]+;", options: .regularExpression) {
            let digits = result[range].dropFirst(2).dropLast()
            let replacement = UInt32(digits).flatMap(Unicode.Scalar.init).map { String(Character($0)) } ?? ""
            result.replaceSubrange(range, with: replacement)
        }

        // &amp; last, so "&amp;quot;" doesn't turn into a quote mark.
        return result.replacingOccurrences(of: "&amp;", with: "&")
    }
}
