import SwiftUI
import StoreKit

/// Tip Jar screen — voluntary support with no paywalls.
struct TipJarView: View {
    @Environment(\.dismiss) private var dismiss
    let store = StoreManager.shared

    @State private var showThankYou = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Support 2TAP")
                            .font(.system(size: 24, weight: .bold, design: .rounded))

                        Text("2TAP is free with no ads. If you enjoy the game, a tip helps keep it updated!")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)

                    // Tip buttons
                    if store.isLoading {
                        ProgressView()
                            .padding(40)
                    } else if store.products.isEmpty {
                        // Products not loaded — show placeholders
                        VStack(spacing: 12) {
                            tipPlaceholder(emoji: "☕", title: "Small Tip", price: "$0.99")
                            tipPlaceholder(emoji: "🎮", title: "Medium Tip", price: "$2.99")
                            tipPlaceholder(emoji: "🏆", title: "Large Tip", price: "$4.99")
                        }
                        .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(store.products) { product in
                                tipButton(product: product)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Stats
                    if store.totalTipsGiven > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.circle.fill")
                                .foregroundStyle(.pink)
                            Text("You've tipped \(store.totalTipsGiven) time\(store.totalTipsGiven == 1 ? "" : "s"). Thank you!")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Tip Jar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .task {
                await store.loadProducts()
            }
            .onChange(of: store.purchaseMessage) { _, message in
                if message != nil {
                    showThankYou = true
                }
            }
            .alert("Thank You!", isPresented: $showThankYou) {
                Button("OK") {
                    store.purchaseMessage = nil
                }
            } message: {
                Text(store.purchaseMessage ?? "")
            }
        }
    }

    private func tipButton(product: Product) -> some View {
        Button {
            Task { await store.purchase(product) }
        } label: {
            HStack {
                let emoji = tipEmoji(for: product.id)
                Text(emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(product.description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .orange.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func tipPlaceholder(emoji: String, title: String, price: String) -> some View {
        HStack {
            Text(emoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("Loading...")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(price)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(.gray.opacity(0.3))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private func tipEmoji(for productID: String) -> String {
        switch productID {
        case StoreManager.tipSmallID: return "☕"
        case StoreManager.tipMediumID: return "🎮"
        case StoreManager.tipLargeID: return "🏆"
        default: return "💝"
        }
    }
}

#Preview {
    TipJarView()
}
