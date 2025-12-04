//
//  RawJSONExtractorError.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 31/5/25.
//

import Foundation

enum RawJSONExtractorError: Error {
    case encodingError
    case keyNotFound
    case parseError
}

// Thank you internet.
struct RawJSONExtractor {
    typealias Error = RawJSONExtractorError
    
    static func extractValue(forKey key: String, from jsonData: Data) throws -> Data {
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw RawJSONExtractorError.encodingError
        }

        // Find `"key":`
        let pattern = #""\#(key)"\s*:"# // matches `"authorization_details":`
        guard let keyRange = jsonString.range(of: pattern, options: .regularExpression) else {
            throw RawJSONExtractorError.keyNotFound
        }

        let scanner = Scanner(string: jsonString)
        scanner.currentIndex = keyRange.upperBound
        scanner.charactersToBeSkipped = .whitespacesAndNewlines

        guard let firstChar = scanner.scanCharacter() else {
            throw RawJSONExtractorError.parseError
        }

        let startIndex = jsonString.index(before: scanner.currentIndex)
        var endIndex = scanner.currentIndex

        switch firstChar {
        case "{", "[":
            var depth = 1
            while depth > 0, !scanner.isAtEnd {
                let ch = scanner.scanCharacter()!
                if ch == firstChar {
                    depth += 1
                } else if ch == (firstChar == "{" ? "}" : "]") {
                    depth -= 1
                }
            }
            endIndex = scanner.currentIndex

        case "\"":
            while !scanner.isAtEnd {
                let ch = scanner.scanCharacter()!
                let prev = jsonString[jsonString.index(before: scanner.currentIndex)]
                if ch == "\"" && prev != "\\" {
                    break
                }
            }
            endIndex = scanner.currentIndex

        default:
            // Number, true, false, null
            scanner.currentIndex = startIndex
            _ = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: ",}"))
            endIndex = scanner.currentIndex
        }

        let rawString = String(jsonString[startIndex..<endIndex])
        guard let data = rawString.data(using: .utf8) else {
            throw RawJSONExtractorError.encodingError
        }

        return data
    }
}
