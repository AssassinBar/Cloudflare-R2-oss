import SwiftUI

struct AddTradeView: View {
    @EnvironmentObject private var tradeStore: TradeStore
    @EnvironmentObject private var notificationManager: NotificationManager

    var onComplete: (() -> Void)?

    @State private var selectedAsset: CryptoAsset = CryptoAsset.catalog[0]
    @State private var tradeType: TradeType = .spot
    @State private var direction: TradeDirection = .long
    @State private var entryPrice = ""
    @State private var quantity = ""
    @State private var leverage = "10"
    @State private var fee = ""
    @State private var note = ""
    @State private var showCryptoPicker = false
    @State private var showSuccess = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                header
                    .staggeredAppear(index: 0)

                cryptoSelector
                    .staggeredAppear(index: 1)

                typeSelector
                    .staggeredAppear(index: 2)

                if tradeType == .futures {
                    directionSelector
                        .staggeredAppear(index: 3)
                        .transition(.opacity)
                }

                inputFields
                    .staggeredAppear(index: 4)

                submitButton
                    .staggeredAppear(index: 5)
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 110)
            .animation(.easeOut(duration: 0.25), value: tradeType)
        }
        .overlay {
            if showSuccess {
                successOverlay
            }
        }
        .sheet(isPresented: $showCryptoPicker) {
            CryptoPickerView(selectedAsset: $selectedAsset)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("添加交易")
                .font(.system(size: 26, weight: .semibold))
                .tracking(-0.4)
                .foregroundStyle(LiquidGlassTheme.textPrimary)
            Text("记录现货或合约的入场信息")
                .font(.system(size: 14))
                .foregroundStyle(LiquidGlassTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cryptoSelector: some View {
        Button {
            showCryptoPicker = true
        } label: {
            HStack(spacing: 14) {
                CryptoIconView(symbol: selectedAsset.symbol, size: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedAsset.displaySymbol)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(LiquidGlassTheme.textPrimary)
                    Text(selectedAsset.name)
                        .font(.system(size: 12))
                        .foregroundStyle(LiquidGlassTheme.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LiquidGlassTheme.textTertiary)
            }
            .padding(14)
            .liquidGlass(cornerRadius: 16, opacity: 0.06, borderOpacity: 0.1)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var typeSelector: some View {
        HStack(spacing: 10) {
            ForEach(TradeType.allCases) { type in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        tradeType = type
                    }
                } label: {
                    Text(type.rawValue)
                        .font(.system(size: 14, weight: tradeType == type ? .medium : .regular))
                        .foregroundStyle(
                            tradeType == type
                                ? LiquidGlassTheme.textPrimary
                                : LiquidGlassTheme.textTertiary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(tradeType == type ? 0.1 : 0.03))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    Color.white.opacity(tradeType == type ? 0.16 : 0.06),
                                    lineWidth: 0.5
                                )
                        }
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    private var directionSelector: some View {
        HStack(spacing: 10) {
            ForEach(TradeDirection.allCases) { dir in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        direction = dir
                    }
                } label: {
                    Text(dir.rawValue)
                        .font(.system(size: 14, weight: direction == dir ? .medium : .regular))
                        .foregroundStyle(
                            direction == dir
                                ? (dir == .long ? LiquidGlassTheme.profitGreen : LiquidGlassTheme.lossRed)
                                : LiquidGlassTheme.textTertiary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.03))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                        }
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    private var inputFields: some View {
        VStack(spacing: 12) {
            GlassTextField(
                placeholder: "入场价格 (USDT)",
                text: $entryPrice,
                icon: "arrow.down.to.line",
                keyboardType: .decimalPad
            )

            GlassTextField(
                placeholder: "数量",
                text: $quantity,
                icon: "number",
                keyboardType: .decimalPad
            )

            if tradeType == .futures {
                GlassTextField(
                    placeholder: "杠杆倍数",
                    text: $leverage,
                    icon: "scalemass",
                    keyboardType: .numberPad
                )
            }

            GlassTextField(
                placeholder: "手续费 (可选)",
                text: $fee,
                icon: "percent",
                keyboardType: .decimalPad
            )

            GlassTextField(
                placeholder: "备注 (可选)",
                text: $note,
                icon: "text.quote"
            )
        }
    }

    private var submitButton: some View {
        Button {
            submitTrade()
        } label: {
            Text("保存交易")
                .glassButtonStyle(isEnabled: canSubmit)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!canSubmit)
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(LiquidGlassTheme.profitGreen)

                Text("已保存")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(LiquidGlassTheme.textPrimary)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 32)
            .liquidGlass(cornerRadius: 20, opacity: 0.12, borderOpacity: 0.15)
        }
        .transition(.opacity)
    }

    private var canSubmit: Bool {
        guard let price = Double(entryPrice), price > 0,
              let qty = Double(quantity), qty > 0 else { return false }
        return true
    }

    private func submitTrade() {
        guard let price = Double(entryPrice),
              let qty = Double(quantity) else { return }

        let trade = TradeRecord(
            cryptoSymbol: selectedAsset.symbol,
            tradeType: tradeType,
            direction: tradeType == .futures ? direction : nil,
            entryPrice: price,
            quantity: qty,
            leverage: tradeType == .futures ? Int(leverage) : nil,
            fee: Double(fee) ?? 0,
            note: note
        )

        tradeStore.addTrade(trade)

        if tradeType == .futures {
            notificationManager.notifyTradeReminder(symbol: selectedAsset.symbol)
        }

        withAnimation(.easeOut(duration: 0.25)) {
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.25)) {
                showSuccess = false
            }
            resetForm()
            onComplete?()
        }
    }

    private func resetForm() {
        entryPrice = ""
        quantity = ""
        fee = ""
        note = ""
        leverage = "10"
    }
}

// MARK: - Crypto Picker

struct CryptoPickerView: View {
    @Binding var selectedAsset: CryptoAsset
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredAssets: [CryptoAsset] {
        if searchText.isEmpty { return CryptoAsset.catalog }
        return CryptoAsset.catalog.filter {
            $0.symbol.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackground()

                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredAssets) { asset in
                            Button {
                                selectedAsset = asset
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    CryptoIconView(symbol: asset.symbol, size: 36)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(asset.displaySymbol)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(LiquidGlassTheme.textPrimary)
                                        Text(asset.name)
                                            .font(.system(size: 11))
                                            .foregroundStyle(LiquidGlassTheme.textTertiary)
                                    }

                                    Spacer()

                                    if asset.id == selectedAsset.id {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(LiquidGlassTheme.textSecondary)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .liquidGlass(cornerRadius: 12, opacity: 0.04, borderOpacity: 0.08)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("选择币种")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(LiquidGlassTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
