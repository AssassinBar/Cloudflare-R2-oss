import SwiftUI

struct XiaomiAuthView: View {
    @ObservedObject var cloud = XiaomiCloud.shared
    @ObservedObject var settings = AppSettings.shared
    @State private var user = ""
    @State private var password = ""
    @State private var otp = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("小米账号 / 小爱音箱")
                .font(.headline)
                .foregroundStyle(.white)
            Text("扫码或登录小米账号，授权家里的小爱音箱。之后 Cursor 需要确认时，会用小爱同学原声播报。")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))

            HStack(alignment: .top, spacing: 16) {
                qrPane
                VStack(alignment: .leading, spacing: 8) {
                    Text(cloud.status)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(cloud.authorized ? XiaoAiTheme.success : XiaoAiTheme.glow)
                    if cloud.authorized {
                        speakerPicker
                        Toggle("播报前播放小爱提示音（唤醒音效）", isOn: $settings.playXiaoAiChime)
                        Picker("播报通道", selection: $settings.broadcastChannel) {
                            Text("仅小爱音箱").tag("speaker")
                            Text("音箱 + 本机").tag("both")
                            Text("仅本机").tag("local")
                        }
                        HStack {
                            Button("刷新音箱") {
                                Task { await cloud.refreshSpeakers() }
                            }
                            Button("试听播报") {
                                Task { await cloud.testSpeak() }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(XiaoAiTheme.orange)
                            Button("退出登录", role: .destructive) { cloud.logout() }
                        }
                    } else {
                        loginForm
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(XiaoAiTheme.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var qrPane: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .frame(width: 168, height: 168)
                if let image = cloud.qrImage {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 156, height: 156)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 42))
                            .foregroundStyle(.black.opacity(0.55))
                        Text(cloud.busy ? "获取中…" : "点击获取二维码")
                            .font(.caption2)
                            .foregroundStyle(.black.opacity(0.55))
                    }
                }
            }
            Button(cloud.qrImage == nil ? "扫码登录小米账号" : "刷新二维码") {
                cloud.startQRLogin()
            }
            .disabled(cloud.busy && cloud.qrImage == nil)
            Text(cloud.qrHint)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 168)
                .multilineTextAlignment(.center)
        }
    }

    private var loginForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("小米账号（手机号 / 邮箱）", text: $user)
                .textFieldStyle(.roundedBorder)
            SecureField("密码", text: $password)
                .textFieldStyle(.roundedBorder)
            if cloud.needsOTP {
                TextField("短信 / 邮箱验证码", text: $otp)
                    .textFieldStyle(.roundedBorder)
            }
            Button("登录并授权小爱音箱") {
                Task { await cloud.login(user: user, password: password, otp: otp.isEmpty ? nil : otp) }
            }
            .buttonStyle(.borderedProminent)
            .tint(XiaoAiTheme.orange)
            .disabled(user.isEmpty || password.isEmpty || cloud.busy)
        }
    }

    private var speakerPicker: some View {
        Group {
            if cloud.speakers.isEmpty {
                Text("未发现小爱音箱。确认音箱已联网，并属于这个小米账号。")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                Picker("播报音箱", selection: $settings.selectedSpeakerId) {
                    ForEach(cloud.speakers) { speaker in
                        Text("\(speaker.name)\(speaker.isOnline ? "" : " · 离线")")
                            .tag(speaker.deviceID)
                    }
                }
            }
        }
    }
}
