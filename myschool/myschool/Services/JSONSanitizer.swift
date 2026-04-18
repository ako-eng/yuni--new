import Foundation

/// 部分后端/爬虫写入的 JSON 在字符串字段内含有**未转义**的 U+0000…U+001F，标准 `JSONDecoder` 会报 `Invalid control character`。
/// 仅在**双引号字符串内部**将裸控制字符改为 `\uXXXX`，不改变键名外的空白。
enum JSONSanitizer {
    static func escapeControlCharactersInJSONStrings(_ json: String) -> String {
        var out = ""
        var i = json.startIndex
        var inString = false
        var escaped = false
        while i < json.endIndex {
            let ch = json[i]
            if inString {
                if escaped {
                    out.append(ch)
                    escaped = false
                    i = json.index(after: i)
                    continue
                }
                if ch == "\\" {
                    escaped = true
                    out.append(ch)
                    i = json.index(after: i)
                    continue
                }
                if ch == "\"" {
                    inString = false
                    out.append(ch)
                    i = json.index(after: i)
                    continue
                }
                let v = ch.unicodeScalars.first?.value ?? 0
                if v < 0x20 {
                    out.append(String(format: "\\u%04x", v))
                } else {
                    out.append(ch)
                }
            } else {
                if ch == "\"" {
                    inString = true
                }
                out.append(ch)
            }
            i = json.index(after: i)
        }
        return out
    }

    static func sanitizeJSONData(_ data: Data) -> Data {
        guard let s = String(data: data, encoding: .utf8) else { return data }
        let fixed = escapeControlCharactersInJSONStrings(s)
        return Data(fixed.utf8)
    }
}
