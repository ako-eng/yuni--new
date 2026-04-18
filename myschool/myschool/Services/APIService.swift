import CryptoKit
import Foundation

// MARK: - Configuration

enum APIConfiguration {
    /// 校园通知后端根地址（固定公网 IP，与 Flask 默认端口 5000 一致；不可在 App 内修改）。
    static let fixedPublicAPIRoot = "http://134.175.183.224:5000"

    static var baseURLString: String { fixedPublicAPIRoot }

    static var baseURL: URL {
        guard let u = URL(string: fixedPublicAPIRoot) else {
            fatalError("Invalid fixedPublicAPIRoot")
        }
        return u
    }

    /// 清除旧版本写入的「手写 / 自动探测」地址，避免历史 UserDefaults 覆盖逻辑虽已移除但仍残留键值。
    static func clearLegacyUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "myschool.api.baseURL")
        UserDefaults.standard.removeObject(forKey: "myschool.api.effectiveBaseURL")
    }
}

// MARK: - DTOs

struct NoticesPageResponse {
    let items: [NoticeItemDTO]
    let total: Int
    let page: Int
    let perPage: Int
    let pages: Int
}

struct NoticeItemDTO {
    let title: String
    let url: String
    let date: String
    let category: String
    let tags: [String]
    let content: String
    let publishDate: String?
    let department: String?
    let attachments: [AttachmentDTO]
    let sourceUrl: String
}

struct AttachmentDTO {
    let resolvedString: String
}

struct CategoriesResponse: Codable {
    let categories: [CategoryStatDTO]
    let totalNotices: Int
    let allTags: [String]

    enum CodingKeys: String, CodingKey {
        case categories
        case totalNotices = "total_notices"
        case allTags = "all_tags"
    }
}

struct CategoryStatDTO: Codable {
    let name: String
    let count: Int
    let tags: [String]
}

struct HealthResponse: Codable {
    let status: String
}

struct APIErrorBody: Codable {
    let status: String?
    let message: String?
}

// MARK: - Mapping

enum NoticeMapping {
    static func stableId(url: String) -> String {
        let data = Data(url.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func summary(from content: String, maxLen: Int = 100) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxLen else { return trimmed }
        let idx = trimmed.index(trimmed.startIndex, offsetBy: maxLen)
        return String(trimmed[..<idx]) + "…"
    }

    static func parseDate(_ ymd: String) -> Date {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: ymd) ?? Date()
    }

    static func source(department: String?, sourceUrl: String) -> String {
        if let d = department, !d.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return d
        }
        guard let u = URL(string: sourceUrl), let host = u.host else {
            return "校园通知"
        }
        return host
    }

    static func notice(from dto: NoticeItemDTO) -> Notice {
        let id = stableId(url: dto.url)
        let cat = NoticeCategory(apiCategory: dto.category) ?? .general
        let attach = dto.attachments.map(\.resolvedString).filter { !$0.isEmpty }
        return Notice(
            id: id,
            title: dto.title,
            summary: summary(from: dto.content),
            content: dto.content,
            category: cat,
            source: source(department: dto.department, sourceUrl: dto.sourceUrl),
            publishDate: parseDate(dto.date),
            isRead: false,
            isImportant: false,
            isUrgent: false,
            attachments: attach,
            url: dto.url,
            sourceURL: dto.sourceUrl,
            tags: dto.tags
        )
    }
}

// MARK: - Service

actor APIService {
    static let shared = APIService()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func healthCheck() async -> Bool {
        guard let url = URL(string: "/api/health", relativeTo: APIConfiguration.baseURL)?.absoluteURL else {
            return false
        }
        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
            let body = try decoder.decode(HealthResponse.self, from: data)
            return body.status == "ok"
        } catch {
            return false
        }
    }

    func login(studentId: String, password: String) async throws {
        let url = APIConfiguration.baseURL.appendingPathComponent("api/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try enc.encode(
            LoginBody(studentId: studentId, password: password)
        )
        let (data, response) = try await session.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        if (200 ..< 300).contains(code) {
            return
        }
        if let err = try? decoder.decode(APIErrorBody.self, from: data), let msg = err.message, !msg.isEmpty {
            throw NSError(domain: "APIService", code: code, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        let text = String(data: data, encoding: .utf8) ?? ""
        throw NSError(
            domain: "APIService",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: text.isEmpty ? "登录失败（HTTP \(code)）" : text]
        )
    }

    func fetchNotices(
        page: Int = 1,
        perPage: Int = 10,
        keyword: String? = nil,
        category: String? = nil,
        tag: String? = nil,
        baseURL rootOverride: URL? = nil
    ) async throws -> NoticesPageResponse {
        let root = rootOverride ?? APIConfiguration.baseURL
        var components = URLComponents(url: root.appendingPathComponent("api/notices"), resolvingAgainstBaseURL: true)!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage)),
        ]
        if let keyword, !keyword.isEmpty {
            items.append(URLQueryItem(name: "keyword", value: keyword))
        }
        if let category, !category.isEmpty {
            items.append(URLQueryItem(name: "category", value: category))
        }
        if let tag, !tag.isEmpty {
            items.append(URLQueryItem(name: "tag", value: tag))
        }
        components.queryItems = items
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await session.data(from: url)
        let http = response as? HTTPURLResponse
        guard let code = http?.statusCode else {
            throw URLError(.badServerResponse)
        }

        if code == 500 {
            if let err = try? decoder.decode(APIErrorBody.self, from: data), let msg = err.message {
                throw NSError(domain: "APIService", code: 500, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw NSError(domain: "APIService", code: 500, userInfo: [NSLocalizedDescriptionKey: "服务器错误"])
        }

        guard code == 200 else {
            throw URLError(.badServerResponse)
        }

        let payload = JSONSanitizer.sanitizeJSONData(Self.stripUTF8BOM(data))
        guard !payload.isEmpty else {
            throw NSError(
                domain: "APIService",
                code: -2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "服务器返回空内容（HTTP 200）。请确认 \(url.absoluteString) 是 myschool_back，且 Flask 已监听该端口（勿与其它占用 5001 的程序混淆）。"
                ]
            )
        }

        let flexibleDecoder = JSONDecoder()
        flexibleDecoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            let flexible = try flexibleDecoder.decode(NoticesPageResponseFlexible.self, from: payload)
            return flexible.toResponse()
        } catch {
            let preview = String(data: payload.prefix(400), encoding: .utf8) ?? "(非 UTF-8)"
            throw NSError(
                domain: "APIService",
                code: -3,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "JSON 解析失败：\(error.localizedDescription)。响应开头：\(preview)"
                ]
            )
        }
    }

    /// 去掉 UTF-8 BOM，避免整段解析失败。
    private static func stripUTF8BOM(_ data: Data) -> Data {
        if data.count >= 3, data[0] == 0xEF, data[1] == 0xBB, data[2] == 0xBF {
            return data.dropFirst(3)
        }
        return data
    }

    func fetchCategories(baseURL rootOverride: URL? = nil) async throws -> CategoriesResponse {
        let root = rootOverride ?? APIConfiguration.baseURL
        let url = root.appendingPathComponent("api/categories")
        let (data, response) = try await session.data(from: url)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        if code == 404 {
            if let err = try? decoder.decode(APIErrorBody.self, from: data), let msg = err.message {
                throw NSError(domain: "APIService", code: 404, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw NSError(domain: "APIService", code: 404, userInfo: [NSLocalizedDescriptionKey: "通知数据文件不存在"])
        }
        guard code == 200 else {
            throw URLError(.badServerResponse)
        }
        let payload = JSONSanitizer.sanitizeJSONData(Self.stripUTF8BOM(data))
        guard !payload.isEmpty else {
            throw NSError(domain: "APIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "分类接口返回空内容"])
        }
        return try decoder.decode(CategoriesResponse.self, from: payload)
    }

    func triggerCrawl() async throws {
        var request = URLRequest(url: APIConfiguration.baseURL.appendingPathComponent("api/crawl/trigger"))
        request.httpMethod = "POST"
        let (data, response) = try await session.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        if code != 200 {
            if let err = try? decoder.decode(APIErrorBody.self, from: data), let msg = err.message {
                throw NSError(domain: "APIService", code: code, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw URLError(.badServerResponse)
        }
    }

    /// `POST /api/notices/add` — 教师发布通知（需后端 myschool_back 已支持）。
    func publishTeacherNotice(
        title: String,
        content: String,
        category: String,
        tags: [String],
        department: String,
        baseURL rootOverride: URL? = nil
    ) async throws {
        let root = rootOverride ?? APIConfiguration.baseURL
        let addURL = root.appendingPathComponent("api/notices").appendingPathComponent("add")
        var request = URLRequest(url: addURL)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        let tagsString = tags.joined(separator: ",")
        request.httpBody = try enc.encode(
            TeacherPublishBody(title: title, content: content, category: category, tags: tagsString, department: department)
        )
        let (data, response) = try await session.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        if (200 ..< 300).contains(code) {
            return
        }
        if let err = try? decoder.decode(APIErrorBody.self, from: data), let msg = err.message, !msg.isEmpty {
            throw NSError(domain: "APIService", code: code, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        let text = String(data: data, encoding: .utf8) ?? ""
        throw NSError(
            domain: "APIService",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: text.isEmpty ? "发布失败（HTTP \(code)）" : text]
        )
    }
}

private struct LoginBody: Encodable {
    let studentId: String
    let password: String
}

private struct TeacherPublishBody: Encodable {
    let title: String
    let content: String
    let category: String
    /// 英文逗号分隔，与后端约定一致。
    let tags: String
    let department: String
}

// MARK: - Flexible page decode

private struct AttachmentObjectDTO: Codable {
    let url: String?
    let name: String?
    let title: String?
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }
    init?(intValue: Int) { nil }
}

/// Decodes arbitrary JSON to advance the decoder (skip unknown attachment shapes).
private struct SkipAny: Decodable {
    init(from decoder: Decoder) throws {
        if var unkeyed = try? decoder.unkeyedContainer() {
            while !unkeyed.isAtEnd { _ = try? unkeyed.decode(SkipAny.self) }
        } else if let keyed = try? decoder.container(keyedBy: DynamicCodingKey.self) {
            for key in keyed.allKeys { _ = try? keyed.decode(SkipAny.self, forKey: key) }
        } else {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() { return }
            if (try? container.decode(Bool.self)) != nil { return }
            if (try? container.decode(Int.self)) != nil { return }
            if (try? container.decode(Double.self)) != nil { return }
            if (try? container.decode(String.self)) != nil { return }
        }
    }
}

private struct NoticeItemDTOWithFlexibleAttachments: Decodable {
    let title: String
    let url: String
    let date: String
    let category: String
    let tags: [String]
    let content: String
    let publishDate: String?
    let department: String?
    let sourceUrl: String

    let attachmentStrings: [String]

    /// 与 `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase` 配合：用 camelCase，勿再写 `source_url` 等，否则易与解码策略冲突。
    enum CodingKeys: String, CodingKey {
        case title, url, date, category, tags, content, publishDate, department, attachments, sourceUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        url = try c.decodeIfPresent(String.self, forKey: .url) ?? ""
        date = try c.decodeIfPresent(String.self, forKey: .date) ?? ""
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? ""
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        content = try c.decodeIfPresent(String.self, forKey: .content) ?? ""
        publishDate = try c.decodeIfPresent(String.self, forKey: .publishDate)
        department = try c.decodeIfPresent(String.self, forKey: .department)
        sourceUrl = try c.decodeIfPresent(String.self, forKey: .sourceUrl) ?? ""

        if let strings = try? c.decode([String].self, forKey: .attachments) {
            attachmentStrings = strings
        } else if var nested = try? c.nestedUnkeyedContainer(forKey: .attachments) {
            var out: [String] = []
            while !nested.isAtEnd {
                if let s = try? nested.decode(String.self) {
                    if !s.isEmpty { out.append(s) }
                } else if let obj = try? nested.decode(AttachmentObjectDTO.self) {
                    let piece = obj.url ?? obj.name ?? obj.title ?? ""
                    if !piece.isEmpty { out.append(piece) }
                } else {
                    _ = try? nested.decode(SkipAny.self)
                }
            }
            attachmentStrings = out
        } else {
            attachmentStrings = []
        }
    }
}

private struct NoticesPageResponseFlexible: Decodable {
    let total: Int
    let page: Int
    let perPage: Int
    let pages: Int
    let items: [NoticeItemDTOWithFlexibleAttachments]

    enum CodingKeys: String, CodingKey {
        case total, page, perPage, pages, items
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        total = try c.decodeIfPresent(Int.self, forKey: .total) ?? 0
        page = try c.decodeIfPresent(Int.self, forKey: .page) ?? 1
        perPage = try c.decodeIfPresent(Int.self, forKey: .perPage) ?? 10
        pages = try c.decodeIfPresent(Int.self, forKey: .pages) ?? 0
        items = try c.decodeIfPresent([NoticeItemDTOWithFlexibleAttachments].self, forKey: .items) ?? []
    }

    func toResponse() -> NoticesPageResponse {
        let mapped = items.map { dto in
            NoticeItemDTO(
                title: dto.title,
                url: dto.url,
                date: dto.date,
                category: dto.category,
                tags: dto.tags,
                content: dto.content,
                publishDate: dto.publishDate,
                department: dto.department,
                attachments: dto.attachmentStrings.map { AttachmentDTO(resolvedString: $0) },
                sourceUrl: dto.sourceUrl
            )
        }
        return NoticesPageResponse(
            items: mapped,
            total: total,
            page: page,
            perPage: perPage,
            pages: pages
        )
    }
}
