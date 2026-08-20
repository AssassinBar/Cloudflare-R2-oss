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
    @State private var successScale: CGFloat = 0.5

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                header
                    .staggeredAppear(index: 0)

                cryptoSelector
                    .staggeredAppear(index: 1)

                typeSelector
                    .staggeredAppear(index: 2)

                if tradeType == .futures {
                    directionSelector
                        .staggeredAppear(index: 3)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                inputFields
                    .staggeredAppear(index: 4)

                submitButton
                    .staggeredAppear(index: 5)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: tradeType)
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
        VStack(alignment: .leading, spacing: 4) {
            Text("添加交易")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("记录现货或合约交易的盈亏")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cryptoSelector: some View {
        Button {
            showCryptoPicker = true
        } label: {
            HStack(spacing: 14) {
                CryptoIconView(symbol: selectedAsset.symbol, size: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedAsset.displaySymbol)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(selectedAsset.name)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(16)
            .liquidGlass(cornerRadius: 18, opacity: 0.1)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var typeSelector: some View {
        HStack(spacing: 12) {
            ForEach(TradeType.allCases) { type in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        tradeType = type
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: type.icon)
                        Text(type.rawValue)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(tradeType == type ? .white : .white.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .liquidGlass(
                        cornerRadius: 14,
                        opacity: tradeType == type ? 0.18 : 0.06
                    )
                    .overlay {
                        if tradeType == type {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(LiquidGlassTheme.accentCyan.opacity(0.4), lineWidth: 0.8)
                        }
                    }
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    private var directionSelector: some View {
        HStack(spacing: 12) {
            ForEach(TradeDirection.allCases) { dir in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        direction = dir
                    }
                } label: {
                    Text(dir.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(direction == dir ? .white : .white.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    direction == dir
                                        ? (dir == .long
                                            ? LiquidGlassTheme.profitGreen.opacity(0.25)
                                            : LiquidGlassTheme.lossRed.opacity(0.25))
                                        : Color.white.opacity(0.06)
                                )
                        }
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    private var inputFields: some View {
        VStack(spacing: 14) {
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
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("保存交易")
            }
            .glassButtonStyle(isEnabled: canSubmit)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!canSubmit)
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(LiquidGlassTheme.profitGreen)
                    .scaleEffect(successScale)

                Text("交易已保存")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(40)
            .liquidGlass(cornerRadius: 28, opacity: 0.2)
            .scaleEffect(successScale)
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

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showSuccess = true
            successScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showSuccess = false
                successScale = 0.5
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
                    LazyVStack(spacing: 8) {
                        ForEach(Array(filteredAssets.enumerated()), id: \.element.id) { index, asset in
                            Button {
                                selectedAsset = asset
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    CryptoIconView(symbol: asset.symbol, size: 40)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(asset.displaySymbol)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text(asset.name)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.45))
                                    }

                                    Spacer()

                                    if asset.id == selectedAsset.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(LiquidGlassTheme.accentCyan)
                                    }
                                }
                                .padding(12)
                                .liquidGlass(cornerRadius: 14, opacity: 0.08)
                            }
                            .buttonStyle(PressableButtonStyle())
                            .staggeredAppear(index: min(index, 15))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("选择币种")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索币种...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(LiquidGlassTheme.accentCyan)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
