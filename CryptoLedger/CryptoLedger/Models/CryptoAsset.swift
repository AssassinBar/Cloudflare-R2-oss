import Foundation

struct CryptoAsset: Identifiable, Hashable {
    let id: String
    let symbol: String
    let name: String
    let iconURL: URL?

    var displaySymbol: String { symbol.uppercased() }

    static let catalog: [CryptoAsset] = [
        CryptoAsset(id: "btc", symbol: "BTC", name: "Bitcoin",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/1/small/bitcoin.png")),
        CryptoAsset(id: "eth", symbol: "ETH", name: "Ethereum",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/279/small/ethereum.png")),
        CryptoAsset(id: "bnb", symbol: "BNB", name: "BNB",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/825/small/bnb-icon2_2x.png")),
        CryptoAsset(id: "sol", symbol: "SOL", name: "Solana",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/4128/small/solana.png")),
        CryptoAsset(id: "xrp", symbol: "XRP", name: "Ripple",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/44/small/xrp-symbol-white-128.png")),
        CryptoAsset(id: "ada", symbol: "ADA", name: "Cardano",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/975/small/cardano.png")),
        CryptoAsset(id: "doge", symbol: "DOGE", name: "Dogecoin",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/5/small/dogecoin.png")),
        CryptoAsset(id: "dot", symbol: "DOT", name: "Polkadot",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/12171/small/polkadot.png")),
        CryptoAsset(id: "avax", symbol: "AVAX", name: "Avalanche",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/12559/small/Avalanche_Circle_RedWhite_Trans.png")),
        CryptoAsset(id: "matic", symbol: "MATIC", name: "Polygon",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/4713/small/polygon.png")),
        CryptoAsset(id: "link", symbol: "LINK", name: "Chainlink",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/877/small/chainlink-new-logo.png")),
        CryptoAsset(id: "ltc", symbol: "LTC", name: "Litecoin",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/2/small/litecoin.png")),
        CryptoAsset(id: "uni", symbol: "UNI", name: "Uniswap",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/12504/small/uni.jpg")),
        CryptoAsset(id: "atom", symbol: "ATOM", name: "Cosmos",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/1481/small/cosmos_hub.png")),
        CryptoAsset(id: "near", symbol: "NEAR", name: "NEAR Protocol",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/10365/small/near.jpg")),
        CryptoAsset(id: "apt", symbol: "APT", name: "Aptos",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/26455/small/aptos_round.png")),
        CryptoAsset(id: "arb", symbol: "ARB", name: "Arbitrum",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/16547/small/arb.jpg")),
        CryptoAsset(id: "op", symbol: "OP", name: "Optimism",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/25244/small/Optimism.png")),
        CryptoAsset(id: "sui", symbol: "SUI", name: "Sui",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/26375/small/sui_asset.jpeg")),
        CryptoAsset(id: "pepe", symbol: "PEPE", name: "Pepe",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/29850/small/pepe-token.jpeg")),
        CryptoAsset(id: "shib", symbol: "SHIB", name: "Shiba Inu",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/11939/small/shiba.png")),
        CryptoAsset(id: "trx", symbol: "TRX", name: "TRON",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/1094/small/tron-logo.png")),
        CryptoAsset(id: "ton", symbol: "TON", name: "Toncoin",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/17980/small/ton_symbol.png")),
        CryptoAsset(id: "fil", symbol: "FIL", name: "Filecoin",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/12817/small/filecoin.png")),
        CryptoAsset(id: "inj", symbol: "INJ", name: "Injective",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/12882/small/Secondary_Symbol.png")),
        CryptoAsset(id: "wld", symbol: "WLD", name: "Worldcoin",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/31069/small/worldcoin.jpeg")),
        CryptoAsset(id: "sei", symbol: "SEI", name: "Sei",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/28205/small/Sei_Logo_-_Transparent.png")),
        CryptoAsset(id: "tia", symbol: "TIA", name: "Celestia",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/31967/small/tia.jpg")),
        CryptoAsset(id: "ftm", symbol: "FTM", name: "Fantom",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/4001/small/Fantom_round.png")),
        CryptoAsset(id: "aave", symbol: "AAVE", name: "Aave",
                    iconURL: URL(string: "https://assets.coingecko.com/coins/images/12645/small/AAVE.png")),
    ]

    static func find(bySymbol symbol: String) -> CryptoAsset? {
        catalog.first { $0.symbol.uppercased() == symbol.uppercased() }
    }
}
