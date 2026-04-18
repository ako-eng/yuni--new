import SwiftUI

struct TeacherPublishNoticeView: View {
    @State private var titleText = ""
    @State private var contentText = ""
    @State private var category: NoticeCategory = .general
    @State private var departmentText = ""
    @State private var tagsText = ""
    @State private var isSubmitting = false
    @State private var feedback: String?

    var body: some View {
        Form {
            Section {
                TextField("标题", text: $titleText)
                Picker("分类", selection: $category) {
                    ForEach(NoticeCategory.allCases) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }
                TextField("发布单位（可选）", text: $departmentText)
                TextField("标签，用逗号分隔（可选）", text: $tagsText)
            } header: {
                Text("基本信息")
            }

            Section {
                TextEditor(text: $contentText)
                    .frame(minHeight: 160)
            } header: {
                Text("正文")
            } footer: {
                Text("将提交至「设置」中配置的校园通知后端，并写入服务器上的通知数据文件。")
            }

            if let feedback {
                Section {
                    Text(feedback)
                        .font(.caption)
                        .foregroundStyle(feedback.hasPrefix("发布成功") ? AppColors.mintGreen : AppColors.softRed)
                }
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("提交发布")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isSubmitting || !canSubmit)
            }
        }
        .navigationTitle("发布通知")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canSubmit: Bool {
        !titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func parsedTags() -> [String] {
        tagsText.split { $0 == "," || $0 == "，" }
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    @MainActor
    private func submit() async {
        feedback = nil
        if NoticeStore.shared.usingMockFallback {
            feedback = "当前为本地演示数据，请先在设置中连接校园通知接口后再发布。"
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        let t = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let c = contentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let dept = departmentText.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await APIService.shared.publishTeacherNotice(
                title: t,
                content: c,
                category: category.apiCategoryLabel,
                tags: parsedTags(),
                department: dept
            )
            feedback = "发布成功，列表已刷新。"
            titleText = ""
            contentText = ""
            tagsText = ""
            await NoticeStore.shared.refresh()
        } catch {
            feedback = error.localizedDescription
        }
    }
}
