import SwiftUI
import StoreKit
import ApphudSDK

struct PaywallView: View {
  @Environment(\ .dismiss) var dismiss
  @ObservedObject var subscriptionManager = SubscriptionManager.shared
  @State private var selectedPlan: SubscriptionPlan? = .yearly
  @State private var isPurchasing = false
  @State private var showCloseButton = true
  
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
      
      VStack(spacing: 16) {
        Image("paywall")
          .resizable()
          .scaledToFill()
          .offset(y: 200)
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
            Text("FLUX AI")
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
        
        VStack(spacing: 12) {
          ForEach(SubscriptionPlan.allCases, id: \ .self) { plan in
            SubscriptionOptionView(plan: plan, selectedPlan: $selectedPlan)
          }
        }
        .padding(.horizontal, 20)
        
        Button(action: purchaseSubscription) {
          Text("Subscribe")
            .font(.system(size: 18, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
              GradientStyles.gradient2
            )
            .foregroundColor(.white)
            .clipShape(Capsule())
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
  
  private func purchaseSubscription() {
    guard let plan = selectedPlan else { return }
    isPurchasing = true
    guard let product = subscriptionManager.productsApphud.first(where: { $0.skProduct?.productIdentifier == plan.productId }) else {
      isPurchasing = false
      return
    }
    subscriptionManager.startPurchase(product: product) { success in
      isPurchasing = false
      if success { dismiss() }
    }
  }
  
  private func restorePurchases() {
    subscriptionManager.restorePurchases { success in
      if success { dismiss() }
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
        .foregroundColor(.red)
      Text(text)
        .font(.system(size: 16))
        .foregroundColor(.white)
    }
  }
}

struct SubscriptionOptionView: View {
  let plan: SubscriptionPlan
  @Binding var selectedPlan: SubscriptionPlan?
  @ObservedObject var subscriptionManager = SubscriptionManager.shared
  
  var body: some View {
    Button(action: { selectedPlan = plan }) {
      HStack(spacing: 12) {
        VStack(alignment: .leading) {
          Text(plan.title)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
          Text(plan.priceSubtitle)
            .font(.system(size: 14))
            .foregroundColor(.gray)
        }
        Spacer()
        Text(subscriptionManager.getProductPrice(for: plan.productId))
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(.white)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .stroke(selectedPlan == plan ? GradientStyles.gradient2 : GradientStyles.gradient3, lineWidth: 2)
      )
    }
  }
}

enum SubscriptionPlan: String, CaseIterable {
  case yearly, weekly
  
  var title: String {
    switch self {
    case .yearly: return "Annual"
    case .weekly: return "Weekly"
    }
  }
  
  var priceSubtitle: String {
    switch self {
    case .yearly: return "$2.08 per week"
    case .weekly: return ""
    }
  }
  
  var productId: String {
    switch self {
    case .yearly: return "yearly_99.99_nottrial"
    case .weekly: return "week_9.99_nottrial"
    }
  }
}

#Preview {
  PaywallView()
}
