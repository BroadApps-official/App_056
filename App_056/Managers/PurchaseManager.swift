import Foundation
import StoreKit
import Combine
import ApphudSDK

class PurchaseManager: NSObject {

  let paywallID = "main"
  let paywallID1 = "Tokens"
  var productsApphud: [ApphudProduct] = []
  var productsApphud1: [ApphudProduct] = []

  override init() {
    super.init()
    print("🛍️ PurchaseManager initialized")
  }

  var hasUnlockedPro: Bool {
    let hasAccess = Apphud.hasPremiumAccess()
    print("🛍️ Checking premium access: \(hasAccess)")
    return hasAccess
  }

  @MainActor
  func returnPrice(product: ApphudProduct) -> String {
    return product.skProduct?.price.stringValue ?? ""
  }

  @MainActor
  func returnPriceSign(product: ApphudProduct) -> String {
    return product.skProduct?.priceLocale.currencySymbol ?? ""
  }

  @MainActor
  func returnName(product: ApphudProduct) -> String {
    guard let subscriptionPeriod = product.skProduct?.subscriptionPeriod else { return "" }

    switch subscriptionPeriod.unit {
    case .day:
      return "Weekly"
    case .week:
      return "Weekly"
    case .month:
      return "Monthly"
    case .year:
      return "Yearly"
    @unknown default:
      return "Unknown"
    }
  }

  @MainActor
  func dateSubscribe() -> String {
    if let subscription = Apphud.subscription() {
      let expirationDate = subscription.expiresDate

      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "MMMM dd, yyyy"
      let formattedDate = dateFormatter.string(from: expirationDate)

      return "until \(formattedDate)"
    }

    return "No active subscription"
  }

  @MainActor
  func startPurchase(produst: ApphudProduct, escaping: @escaping(Bool) -> Void) {
    print("🛍️ Starting purchase for product: \(produst.productId)")
    print("🛍️ Product details:")
    print("  - Price: \(produst.skProduct?.price ?? 0)")
    print("  - StoreKit Product ID: \(produst.skProduct?.productIdentifier ?? "unknown")")
    
    if let period = produst.skProduct?.subscriptionPeriod {
      switch period.unit {
      case .day:
        print("  - Subscription Period: Daily")
      case .week:
        print("  - Subscription Period: Weekly")
      case .month:
        print("  - Subscription Period: Monthly")
      case .year:
        print("  - Subscription Period: Yearly")
      @unknown default:
        print("  - Subscription Period: Unknown")
      }
    } else {
      print("  - Subscription Period: Not available")
    }
    
    let selectedProduct = produst
    
    print("🛍️ Initiating Apphud purchase...")
    
    // Проверяем, что продукт доступен
    guard let skProduct = selectedProduct.skProduct else {
      print("❌ SKProduct is nil")
      escaping(false)
      return
    }
    
    Apphud.purchase(selectedProduct) { [weak self] result in
      guard let self = self else { return }
      
      print("🛍️ Purchase result received")
      print("🛍️ Result success: \(result.success)")
      print("🛍️ Requested product ID: \(produst.productId)")
      
      if let error = result.error {
        print("❌ Purchase error: \(error.localizedDescription)")
        if let apphudError = error as? ApphudError {
          print("❌ Apphud specific error: \(apphudError)")
        }
        if let skError = error as? SKError {
          print("❌ StoreKit error: \(skError.localizedDescription)")
          print("❌ StoreKit error code: \(skError.code.rawValue)")
        }
        escaping(false)
        return
      }
      
      if result.success {
        print("✅ Purchase successful")
        
        if let nonRenewingPurchase = result.nonRenewingPurchase {
          print("✅ Non-renewing purchase details:")
          print("  - Product ID: \(nonRenewingPurchase.productId)")
          escaping(true)
        } else if let subscription = result.subscription {
          print("✅ Subscription details:")
          print("  - Product ID: \(subscription.productId)")
          print("  - Expires Date: \(subscription.expiresDate)")
          print("  - Is Active: \(subscription.isActive())")
          print("  - Original Request: \(produst.productId)")
          
          // Проверяем соответствие запрошенного и полученного продукта
          if subscription.productId != produst.productId {
            print("⚠️ Warning: Received different product than requested")
            print("  - Requested: \(produst.productId)")
            print("  - Received: \(subscription.productId)")
            
            // Если получен другой продукт, считаем это ошибкой
            escaping(false)
            return
          }
          
          escaping(true)
        } else {
          print("❌ Purchase successful but no subscription/purchase found")
          escaping(false)
        }
      } else {
        print("❌ Purchase failed")
        escaping(false)
      }
    }
  }

  @MainActor
  func loadPaywalls(completion: @escaping () -> Void) {
    print("🛍️ Loading paywalls")
    
    Apphud.paywallsDidLoadCallback { [weak self] paywalls, error in
      guard let self = self else { return }
      
      if let error = error {
        print("❌ Error loading paywalls: \(error.localizedDescription)")
        completion()
        return
      }
      
      for paywall in paywalls {
        if paywall.identifier == self.paywallID {
          self.productsApphud = paywall.products
          print("✅ Loaded \(self.productsApphud.count) products for main paywall")
        } else if paywall.identifier == self.paywallID1 {
          self.productsApphud1 = paywall.products
          print("✅ Loaded \(self.productsApphud1.count) products for tokens paywall")
        }
      }
      
      completion()
    }
  }

  @MainActor
  func loadPaywalls1(escaping: @escaping() -> Void) {
    Apphud.paywallsDidLoadCallback { paywalls, arg in
      if let paywall = paywalls.first(where: { $0.identifier == self.paywallID1}) {
        Apphud.paywallShown(paywall)

        let products = paywall.products
        self.productsApphud1 = products

        print(products, "Proddd")
        for i in products {
          print(i.productId, "ID")
        }
        escaping()
      }
    }
  }

  @MainActor
  func restorePurchase(escaping: @escaping(Bool) -> Void) {
    print("🛍️ Starting purchase restoration")
    
    Apphud.restorePurchases { [weak self] subscriptions, _, error in
      guard let self = self else { return }
      
      print("🛍️ Restore result received")
      
      if let error = error {
        print("❌ Restore error: \(error.localizedDescription)")
        if let apphudError = error as? ApphudError {
          print("❌ Apphud specific error: \(apphudError)")
        }
        escaping(false)
        return
      }
      
      if let subscription = subscriptions?.first {
        print("📝 Subscription details:")
        print("  - Product ID: \(subscription.productId)")
        print("  - Expires Date: \(subscription.expiresDate)")

        
        if subscription.isActive() {
          print("✅ Subscription restored successfully")
          escaping(true)
          return
        }
      }
      
      if Apphud.hasActiveSubscription() {
        print("✅ Active subscription found")
        escaping(true)
        return
      }
      
      print("❌ No active subscription found")
      escaping(false)
    }
  }
}
