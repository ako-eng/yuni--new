import SwiftUI

enum NoticeDetailPresentation {
    case pushed
    case sheet
}

struct NoticeDetailView: View {
    let noticeId: String
    var presentation: NoticeDetailPresentation = .pushed

    private let store = NoticeStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showDownloadAlert = false
    @State private var appeared = false
    @State private var readCountDisplay: Int?

    private var notice: Notice? {
        store.notices.first { $0.id == noticeId }
    }

    var body: some View {
        Group {
            if let current = notice {
                detailScroll(notice: current)
            } else {
                missingNoticePlaceholder
            }
        }
        .background(AppColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(notice?.title ?? "通知详情")
        .toolbar {
            if presentation == .sheet {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        withAnimation(AppleSpring.snappy) {
                            store.toggleFavorite(noticeId)
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: store.isFavorited(noticeId) ? "star.fill" : "star")
                            .foregroundStyle(store.isFavorited(noticeId) ? AppColors.warmOrange : AppColors.textSecondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .disabled(notice == nil)

                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .disabled(notice == nil)
                }
            }
        }
        .toolbar(.visible, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            if let n = notice {
                ShareActivitySheet(activityItems: ["【\(n.source)】\(n.title)\n\n\(n.summary)"])
            }
        }
        .alert("附件下载", isPresented: $showDownloadAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("附件将保存到「文件」App 中")
        }
        .onAppear {
            store.markAsRead(noticeId)
            if readCountDisplay == nil {
                readCountDisplay = Int.random(in: 50...500)
            }
            withAnimation(AppleSpring.smooth.delay(0.1)) {
                appeared = true
            }
        }
    }

    private var missingNoticePlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
            Text("无法加载该通知")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
            Text("内容可能已下架或链接无效")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func detailScroll(notice: Notice) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                headerSection(notice: notice)
                    .padding(.bottom, 20)

                Divider()
                    .padding(.horizontal, 20)

                contentSection(notice: notice)
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                attachmentSection(notice: notice)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Header

    private func headerSection(notice: Notice) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(notice.category.color.opacity(0.12))
                    Image(systemName: notice.category.icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(notice.category.color)
                        .frame(width: 16, height: 16)
                }
                .frame(width: 28, height: 28)

                Text(notice.source)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(notice.category.color)

                Spacer()

                if notice.isUrgent {
                    Text("紧急")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColors.warmOrange.gradient)
                        .clipShape(Capsule())
                }

                if notice.isImportant && !notice.isUrgent {
                    Text("重要")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColors.softRed.gradient)
                        .clipShape(Capsule())
                }
            }

            Text(notice.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)

            HStack(spacing: 16) {
                Label(notice.formattedDate, systemImage: "clock")
                if let readCountDisplay {
                    Label("\(readCountDisplay)次阅读", systemImage: "eye")
                }
            }
            .font(.system(size: 12, design: .rounded))
            .foregroundStyle(AppColors.textSecondary.opacity(0.7))
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Content

    private func contentSection(notice: Notice) -> some View {
        Text(notice.content)
            .font(.system(size: 16, design: .rounded))
            .foregroundStyle(AppColors.textPrimary)
            .lineSpacing(8)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
    }

    // MARK: - Attachment

    @ViewBuilder
    private func attachmentSection(notice: Notice) -> some View {
        if notice.hasAttachment {
            VStack(alignment: .leading, spacing: 12) {
                Divider()
                    .padding(.horizontal, 20)

                Text("附件")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppColors.campusBlue.opacity(0.1))
                        Image(systemName: "doc.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.campusBlue)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("通知详情附件.pdf")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppColors.textPrimary)
                        Text("256 KB")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer()

                    Button {
                        showDownloadAlert = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(AppColors.campusBlue)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .padding(12)
                .background(AppColors.cardWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 20)
            }
        }
    }
}
