import SwiftUI
import Combine
import ApphudSDK

@MainActor
class SubscriptionManager: ObservableObject {
  static let shared = SubscriptionManager()
  @Published var productsApphud: [ApphudProduct] = []
  @Published var isSubscribed: Bool = false
  
  private let weeklyProductID = "week_7.99_nottrial."
  private let yearlyProductID = "yearly_39.99_nottrial."
  private let paywallID = "main"
  let buyPublisher = PassthroughSubject<Bool, Never>()
  
  private init() {
    loadProducts()
    checkSubscriptionStatus()
  }
  
  private func loadProducts() {
    Apphud.paywallsDidLoadCallback { paywalls, error in
      if let paywall = paywalls.first(where: { $0.identifier == self.paywallID }) {
        Apphud.paywallShown(paywall)
        let products = paywall.products
        self.productsApphud = products
      } else {
        print("❌ Paywall with id \(self.paywallID) not found")
      }
    }
  }
  
  func checkSubscriptionStatus() {
    Task {
      let result = await Apphud.hasPremiumAccess()
      DispatchQueue.main.async {
        self.isSubscribed = result
        print("✅ Subscribe active: \(result)")
      }
    }
  }
  
  func startPurchase(product: ApphudProduct, escaping: @escaping (Bool) -> Void) {
    Apphud.purchase(product, callback: { [weak self] result in
      guard let self = self else { return }
      
      if let error = result.error {
        print("❌ Error: \(error.localizedDescription)")
        self.buyPublisher.send(false)
        escaping(false)
        return
      }
      
      if let subscription = result.subscription, subscription.isActive() {
        self.buyPublisher.send(true)
        escaping(true)
        return
      }
      
      if let purchase = result.nonRenewingPurchase, purchase.isActive() {
        self.buyPublisher.send(true)
        escaping(true)
        return
      }
      
      if Apphud.hasActiveSubscription() {
        self.buyPublisher.send(true)
        escaping(true)
        return
      }
      
      self.buyPublisher.send(false)
      escaping(false)
    })
  }
  
  func restorePurchases(completion: @escaping (Bool) -> Void) {
    Apphud.restorePurchases { subscriptions, _, error in
      if let error = error {
        print("❌ Error restore \(error.localizedDescription)")
        completion(false)
        return
      }
      
      if subscriptions?.first?.isActive() ?? false || Apphud.hasActiveSubscription() {
        DispatchQueue.main.async {
          self.isSubscribed = true
          completion(true)
        }
      } else {
        completion(false)
      }
    }
  }
  
  func getProductPrice(for productId: String) -> String {
    guard let product = productsApphud.first(where: { $0.skProduct?.productIdentifier == productId }) else {
      return "Loading..."
    }
    guard let skProduct = product.skProduct else {
      return "N/A"
    }
    let price = skProduct.price
    let priceString = "\(skProduct.priceLocale.currencySymbol ?? "$")\(price)"
    print("✅ Price is \(productId): \(priceString)")
    return priceString
  }
}

extension SubscriptionManager {
    func getRawPrice(for plan: SubscriptionPlan) -> Double? {
        guard let product = productsApphud.first(where: { $0.skProduct?.productIdentifier == plan.productId }),
              let price = product.skProduct?.price.doubleValue else {
            return nil
        }
        return price
    }
}
