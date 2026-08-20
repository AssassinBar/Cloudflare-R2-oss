import SwiftUI

struct AuthContainerView: View {
    @State private var showRegister = false

    var body: some View {
        VStack {
            Spacer()

            GlassOrb(size: 72)
                .padding(.bottom, 28)

            if showRegister {
                RegisterView(onSwitchToLogin: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showRegister = false
                    }
                })
                .transition(.opacity)
            } else {
                LoginView(onSwitchToRegister: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showRegister = true
                    }
                })
                .transition(.opacity)
            }

            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

struct LoginView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var tradeStore: TradeStore

    let onSwitchToRegister: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("欢迎回来")
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundStyle(LiquidGlassTheme.textPrimary)

                Text("登录以继续记录交易")
                    .font(.system(size: 14))
                    .foregroundStyle(LiquidGlassTheme.textSecondary)
            }
            .staggeredAppear(index: 0)

            VStack(spacing: 14) {
                GlassTextField(
                    placeholder: "邮箱地址",
                    text: $email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress
                )
                .staggeredAppear(index: 1)

                GlassTextField(
                    placeholder: "密码",
                    text: $password,
                    icon: "lock.fill",
                    isSecure: !showPassword,
                    trailingIcon: showPassword ? "eye.slash.fill" : "eye.fill",
                    onTrailingTap: { showPassword.toggle() }
                )
                .staggeredAppear(index: 2)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(LiquidGlassTheme.lossRed)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Button {
                performLogin()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("登录")
                    }
                }
                .glassButtonStyle(isEnabled: canSubmit)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!canSubmit || isLoading)
            .staggeredAppear(index: 3)

            Button {
                onSwitchToRegister()
            } label: {
                HStack(spacing: 4) {
                    Text("还没有账号？")
                        .foregroundStyle(LiquidGlassTheme.textSecondary)
                    Text("立即注册")
                        .foregroundStyle(LiquidGlassTheme.textPrimary)
                        .fontWeight(.medium)
                }
                .font(.system(size: 14))
            }
            .staggeredAppear(index: 4)
        }
    }

    private var canSubmit: Bool {
        !email.isEmpty && password.count >= 6
    }

    private func performLogin() {
        isLoading = true
        errorMessage = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            do {
                try authService.login(email: email, password: password)
                if let userId = authService.currentUser?.id {
                    tradeStore.setUserId(userId)
                }
            } catch let error as AuthError {
                withAnimation { errorMessage = error.errorDescription }
            } catch {
                withAnimation { errorMessage = "登录失败，请重试" }
            }
            isLoading = false
        }
    }
}

struct RegisterView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var tradeStore: TradeStore

    let onSwitchToLogin: () -> Void

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("创建账号")
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundStyle(LiquidGlassTheme.textPrimary)

                Text("开始记录合约与现货盈亏")
                    .font(.system(size: 14))
                    .foregroundStyle(LiquidGlassTheme.textSecondary)
            }
            .staggeredAppear(index: 0)

            VStack(spacing: 14) {
                GlassTextField(placeholder: "昵称", text: $displayName, icon: "person.fill")
                    .staggeredAppear(index: 1)

                GlassTextField(
                    placeholder: "邮箱地址",
                    text: $email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress
                )
                .staggeredAppear(index: 2)

                GlassTextField(
                    placeholder: "密码（至少6位）",
                    text: $password,
                    icon: "lock.fill",
                    isSecure: !showPassword,
                    trailingIcon: showPassword ? "eye.slash.fill" : "eye.fill",
                    onTrailingTap: { showPassword.toggle() }
                )
                .staggeredAppear(index: 3)

                GlassTextField(
                    placeholder: "确认密码",
                    text: $confirmPassword,
                    icon: "lock.rotation",
                    isSecure: true
                )
                .staggeredAppear(index: 4)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(LiquidGlassTheme.lossRed)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Button {
                performRegister()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("注册")
                    }
                }
                .glassButtonStyle(isEnabled: canSubmit)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!canSubmit || isLoading)
            .staggeredAppear(index: 5)

            Button {
                onSwitchToLogin()
            } label: {
                HStack(spacing: 4) {
                    Text("已有账号？")
                        .foregroundStyle(LiquidGlassTheme.textSecondary)
                    Text("返回登录")
                        .foregroundStyle(LiquidGlassTheme.textPrimary)
                        .fontWeight(.medium)
                }
                .font(.system(size: 14))
            }
            .staggeredAppear(index: 6)
        }
    }

    private var canSubmit: Bool {
        !displayName.isEmpty && !email.isEmpty &&
        password.count >= 6 && password == confirmPassword
    }

    private func performRegister() {
        isLoading = true
        errorMessage = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            do {
                try authService.register(email: email, password: password, displayName: displayName)
                if let userId = authService.currentUser?.id {
                    tradeStore.setUserId(userId)
                }
            } catch let error as AuthError {
                withAnimation { errorMessage = error.errorDescription }
            } catch {
                withAnimation { errorMessage = "注册失败，请重试" }
            }
            isLoading = false
        }
    }
}

// MARK: - Glass Text Field

struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var trailingIcon: String?
    var onTrailingTap: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(isFocused ? LiquidGlassTheme.textSecondary : LiquidGlassTheme.textTertiary)
                    .frame(width: 20)
            }

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .font(.system(size: 15))
            .foregroundStyle(LiquidGlassTheme.textPrimary)
            .focused($isFocused)

            if let trailingIcon {
                Button(action: { onTrailingTap?() }) {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 14))
                        .foregroundStyle(LiquidGlassTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .liquidGlass(cornerRadius: LiquidGlassTheme.buttonCornerRadius, opacity: isFocused ? 0.1 : 0.05, borderOpacity: isFocused ? 0.22 : 0.1)
        .animation(.easeOut(duration: 0.18), value: isFocused)
    }
}
