import SwiftUI
import StoreKit
import ApphudSDK

struct PaywallView: View {
  @Environment(\ .dismiss) var dismiss
  @EnvironmentObject var source: Source
  @State private var isYear = true
  @State private var isPurchasing = false
  @State private var showCloseButton = true
  @State private var isLoading = true
  @State private var showError = false
  @State private var errorMessage = ""
  
  var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [
          Color.black,
          Color.black
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .edgesIgnoringSafeArea(.all)
      
      ScrollView {
        VStack(spacing: 16) {
          Image("paywall")
            .resizable()
            .scaledToFill()
            .frame(height: UIScreen.main.bounds.height * 0.55)
            .clipped()
            .overlay(
              LinearGradient(
                gradient: Gradient(colors: [
                  Color.black.opacity(0.8),
                  Color.black.opacity(0.3),
                  Color.black.opacity(0.0),
                  Color.black.opacity(0.0),
                  Color.black.opacity(1),
                  Color.black.opacity(1)
                ]),
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .overlay(
              Text("AI Avatar")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, -170)
            )
            .overlay(
              Group {
                if showCloseButton {
                  HStack {
                    Button(action: { dismiss() }) {
                      Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color.black.opacity(0.8)))
                    }
                    Spacer()
                  }
                  .padding(.leading, 16)
                  .padding(.top, -170)
                }
              }
            )
            .background(.black)
            .edgesIgnoringSafeArea(.all)
          
          Text("Unreal results with PRO")
            .font(Typography.largeTitle)
            .foregroundColor(.white)
            .padding(.top, -150)
          
          VStack(alignment: .leading, spacing: 10) {
            SubscriptionFeature(text: "High-quality images")
            SubscriptionFeature(text: "Personalized requests")
            SubscriptionFeature(text: "Unlimited generation")
            SubscriptionFeature(text: "Access to exclusive styles")
          }
          .padding(.horizontal, 24)
          .padding(.top, -100)
          
          if isLoading {
            ProgressView()
              .frame(maxWidth: .infinity, maxHeight: 60)
          } else {
            VStack(spacing: 12) {
              if let weeklyProduct = source.purchaseManager.productsApphud.last {
                SubscriptionOptionView(
                  product: weeklyProduct,
                  isSelected: !isYear,
                  onSelect: { isYear = false }
                )
              }
              
              if let yearlyProduct = source.purchaseManager.productsApphud.first {
                SubscriptionOptionView(
                  product: yearlyProduct,
                  isSelected: isYear,
                  onSelect: { isYear = true }
                )
              }
            }
            .padding(.horizontal, 20)
          }
          
          Button(action: purchaseSubscription) {
            if isPurchasing {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
              Text("Subscribe")
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                  GradientStyles.gradient1
                )
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
          }
          .padding(.horizontal, 20)
          .disabled(isPurchasing)
          
          HStack {
            Button("Terms of Service", action: { openURL("https://docs.google.com/document/d/1GswJfATC1Ce4idZ3BPxQPzbdGOERuLafMsnofj7EnX8/edit?usp=sharing") })
            Spacer()
            Button("Restore", action: restorePurchases)
            Spacer()
            Button("Privacy Policy", action: { openURL("https://docs.google.com/document/d/19JuZ3Pxyz3oPI0yPRrzqFeMDqmtDm2HaBBi42R2sKhE/edit?usp=sharing") })
          }
          .font(.system(size: 14))
          .foregroundColor(.gray)
          .padding(.horizontal, 20)
          .padding(.bottom, 40)
        }
      }
    }
    .onAppear {
      Task {
        await source.purchaseManager.loadPaywalls {
          isLoading = false
        }
      }
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        withAnimation { showCloseButton = true }
      }
    }
  }
  
  private func purchaseSubscription() {
    isPurchasing = true
    
    let product = isYear ? 
      source.purchaseManager.productsApphud.first :
      source.purchaseManager.productsApphud.last
    
    guard let selectedProduct = product else {
      isPurchasing = false
      errorMessage = "No subscription products available. Please try again later."
      showError = true
      return
    }
    
    Task { @MainActor in
      source.startPurchase(product: selectedProduct) { success in
        isPurchasing = false
        if success {
          dismiss()
        } else {
          errorMessage = "Purchase failed. Please try again."
          showError = true
        }
      }
    }
  }
  
  private func restorePurchases() {
    Task { @MainActor in
      source.restorePurchase { success in
        if success {
          dismiss()
        } else {
          errorMessage = "Failed to restore purchases. Please try again."
          showError = true
        }
      }
    }
  }
  
  private func openURL(_ urlString: String) {
    if let url = URL(string: urlString) {
      UIApplication.shared.open(url)
    }
  }
}

struct SubscriptionFeature: View {
  let text: String
  var body: some View {
    HStack {
      Image(systemName: "checkmark.circle.fill")
        .foregroundColor(ColorTokens.accent)
      Text(text)
        .font(.system(size: 16))
        .foregroundColor(.white)
    }
  }
}

struct SubscriptionOptionView: View {
  let product: ApphudProduct
  let isSelected: Bool
  let onSelect: () -> Void
  @ObservedObject var subscriptionManager = SubscriptionManager.shared
  
  private var isYearlySubscription: Bool {
    product.skProduct?.subscriptionPeriod?.unit == .year
  }
  
  private var weeklyPrice: String {
    guard let skProduct = product.skProduct else { return "N/A" }
    let price = skProduct.price
    let weeklyPrice = price.doubleValue / 52
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = skProduct.priceLocale
    return formatter.string(from: NSNumber(value: weeklyPrice)) ?? "N/A"
  }
  
  private var weeklyPriceWithoutSymbol: String {
    guard let skProduct = product.skProduct else { return "N/A" }
    let price = skProduct.price
    let weeklyPrice = price.doubleValue / 52
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    formatter.locale = skProduct.priceLocale
    return formatter.string(from: NSNumber(value: weeklyPrice)) ?? "N/A"
  }
  
  private var currencySymbol: String {
    guard let skProduct = product.skProduct else { return "$" }
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = skProduct.priceLocale
    return formatter.currencySymbol ?? "$"
  }
  
  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 12) {
        // Левая часть
        VStack(alignment: .leading, spacing: 4) {
          Text(isYearlySubscription ? "Annual" : "Weekly")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
          if isYearlySubscription {
            Text("\(weeklyPrice) per week")
              .font(.system(size: 14))
              .foregroundColor(.gray)
          }
        }
        
        Spacer()
        
        // Правая часть
        VStack(alignment: .trailing, spacing: 0) {
          HStack(spacing: 8) {
            if isYearlySubscription {
              Text("SAVE 80%")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ColorTokens.orange)
                .cornerRadius(18)
            }
            
            Text(subscriptionManager.getProductPrice(for: product.productId))
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.white)
          }
          Text(isYearlySubscription ? "per year" : "per week")
            .font(.system(size: 14))
            .foregroundColor(.gray)
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .stroke(isSelected ? GradientStyles.gradient1 : GradientStyles.gradient3, lineWidth: 2)
      )
    }
  }
}

final class Source: ObservableObject {
  let purchaseManager = PurchaseManager()

  @MainActor func startPurchase(product: ApphudProduct, escaping: @escaping (Bool) -> Void) {
    purchaseManager.startPurchase(produst: product) { success in
      escaping(success)
    }
  }

  @MainActor func restorePurchase(escaping: @escaping (Bool) -> Void) {
    purchaseManager.restorePurchase { success in
      escaping(success)
    }
  }
}

#Preview {
  let source = Source()
  return PaywallView()
    .environmentObject(source)
}
