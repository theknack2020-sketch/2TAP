import StoreKit
import Observation

/// Manages In-App Purchases (Tip Jar) via StoreKit 2.
///
/// Products:
/// - `twotap.tip.small`  — Small Tip ($0.99)
/// - `twotap.tip.medium` — Medium Tip ($2.99)
/// - `twotap.tip.large`  — Large Tip ($4.99)
///
/// All tips are consumable — no restore needed.
/// Revenue model: voluntary tips, no ads, no paywalls.
@Observable
@MainActor
final class StoreManager {
    static let shared = StoreManager()

    /// Product identifiers — must match App Store Connect
    static let tipSmallID = "twotap.tip.small"
    static let tipMediumID = "twotap.tip.medium"
    static let tipLargeID = "twotap.tip.large"

    private static let allProductIDs: Set<String> = [
        tipSmallID, tipMediumID, tipLargeID
    ]

    /// Loaded products from App Store
    private(set) var products: [Product] = []

    /// Loading state
    private(set) var isLoading = false

    /// Last purchase result message
    var purchaseMessage: String?

    /// Total tips given (persisted)
    var totalTipsGiven: Int {
        get { UserDefaults.standard.integer(forKey: "totalTipsGiven") }
        set { UserDefaults.standard.set(newValue, forKey: "totalTipsGiven") }
    }

    private init() {}

    /// Load products from the App Store.
    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: Self.allProductIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("⚠️ StoreKit: Failed to load products — \(error.localizedDescription)")
        }
    }

    /// Purchase a tip product.
    func purchase(_ product: Product) async {
        purchaseMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Complete the transaction
                    await transaction.finish()
                    totalTipsGiven += 1
                    purchaseMessage = "Thank you for your support! 🧡"
                case .unverified:
                    purchaseMessage = "Purchase could not be verified."
                }
            case .userCancelled:
                break
            case .pending:
                purchaseMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            purchaseMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }

    /// Convenience: get product by ID
    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }
}
