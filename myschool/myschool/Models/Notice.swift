import Foundation

struct Notice: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let summary: String
    let content: String
    let category: NoticeCategory
    let source: String
    let publishDate: Date
    var isRead: Bool
    var isImportant: Bool
    var isUrgent: Bool
    /// Attachment URLs or labels from the API / mock data.
    var attachments: [String]
    /// Original notice page URL (when from API).
    var url: String?
    /// Source listing page URL.
    var sourceURL: String?
    var tags: [String]

    var hasAttachment: Bool { !attachments.isEmpty }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: publishDate, relativeTo: Date())
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: publishDate)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, summary, content, category, source, publishDate
        case isRead, isImportant, isUrgent, attachments, url, sourceURL, tags
    }

    init(
        id: String,
        title: String,
        summary: String,
        content: String,
        category: NoticeCategory,
        source: String,
        publishDate: Date,
        isRead: Bool,
        isImportant: Bool,
        isUrgent: Bool,
        attachments: [String] = [],
        url: String? = nil,
        sourceURL: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.content = content
        self.category = category
        self.source = source
        self.publishDate = publishDate
        self.isRead = isRead
        self.isImportant = isImportant
        self.isUrgent = isUrgent
        self.attachments = attachments
        self.url = url
        self.sourceURL = sourceURL
        self.tags = tags
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        summary = try c.decode(String.self, forKey: .summary)
        content = try c.decode(String.self, forKey: .content)
        category = try c.decode(NoticeCategory.self, forKey: .category)
        source = try c.decode(String.self, forKey: .source)
        let time = try c.decode(Double.self, forKey: .publishDate)
        publishDate = Date(timeIntervalSinceReferenceDate: time)
        isRead = try c.decode(Bool.self, forKey: .isRead)
        isImportant = try c.decode(Bool.self, forKey: .isImportant)
        isUrgent = try c.decode(Bool.self, forKey: .isUrgent)
        attachments = try c.decodeIfPresent([String].self, forKey: .attachments) ?? []
        url = try c.decodeIfPresent(String.self, forKey: .url)
        sourceURL = try c.decodeIfPresent(String.self, forKey: .sourceURL)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(summary, forKey: .summary)
        try c.encode(content, forKey: .content)
        try c.encode(category, forKey: .category)
        try c.encode(source, forKey: .source)
        try c.encode(publishDate.timeIntervalSinceReferenceDate, forKey: .publishDate)
        try c.encode(isRead, forKey: .isRead)
        try c.encode(isImportant, forKey: .isImportant)
        try c.encode(isUrgent, forKey: .isUrgent)
        try c.encode(attachments, forKey: .attachments)
        try c.encodeIfPresent(url, forKey: .url)
        try c.encodeIfPresent(sourceURL, forKey: .sourceURL)
        try c.encode(tags, forKey: .tags)
    }
}
