import SwiftUI

struct MetricPill: View {
    let title: String
    let value: String
    let icon: String
    var tint: Color = AppTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Spacer()
            }

            Text(value)
                .font(AppTheme.title(20))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(AppTheme.title(18))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(AppTheme.caption())
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }
}

struct StatusChip: View {
    let status: DocumentStatus

    private var color: Color {
        switch status {
        case .draft: return AppTheme.textTertiary
        case .confirmed: return AppTheme.accent
        case .completed: return AppTheme.success
        case .cancelled: return AppTheme.danger
        }
    }

    var body: some View {
        Text(status.title)
            .font(AppTheme.caption(12))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(AppTheme.textTertiary)
            Text(title)
                .font(AppTheme.title(18))
                .foregroundStyle(AppTheme.textPrimary)
            Text(message)
                .font(AppTheme.body(14))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(AppTheme.accent)
            .scaleEffect(1.1)
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .softShadow()
    }
}

struct ErrorBanner: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.warning)
            Text(message)
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
            Spacer()
            Button("重试", action: retry)
                .font(AppTheme.caption())
                .foregroundStyle(AppTheme.accent)
        }
        .padding(14)
        .background(AppTheme.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct SearchField: View {
    @Binding var text: String
    var placeholder: String = "搜索"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.textTertiary)
            TextField(placeholder, text: $text)
                .font(AppTheme.body(15))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            if !text.isEmpty {
                Button {
                    withAnimation(AppAnimation.snappy) { text = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .font(AppTheme.body(16))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct ListRowCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .softShadow()
    }
}
