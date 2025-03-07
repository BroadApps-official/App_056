import SwiftUI
import StoreKit
import MessageUI
import ApphudSDK

struct SettingsView: View {
  @Environment(\.dismiss) var dismiss
  @State private var showPaywall = false
  @ObservedObject private var subscriptionManager = SubscriptionManager.shared
  @ObservedObject private var notificationManager = NotificationManager.shared
  @State private var showNotificationAlert = false
  let appID = "6742408277"
  
  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Button(action: { dismiss() }) {
          Image(systemName: "chevron.left")
            .foregroundColor(.white)
            .padding()
            .background(Circle().fill(Color.gray.opacity(0.3)))
        }
        
        Spacer()
        
        Text("Settings")
          .font(Typography.headline)
          .foregroundColor(.white)
        
        Spacer()
        
        if !subscriptionManager.isSubscribed {
          Button(action: { showPaywall = true }) {
            HStack() {
              Image("crown")
                .resizable()
                .frame(width: 12, height: 10)
                .foregroundColor(.white)
              
              Text("Pro")
                .foregroundColor(.white)
                .font(Typography.bodyMedium)
            }
            .padding(.horizontal, 12)
            .frame(width: 69, height: 32)
            .background(GradientStyles.gradient2)
            .clipShape(Capsule())
          }
        } else {
          Spacer().frame(width: 69)
        }
        
      }
      .padding(.horizontal, 16)
      .padding(.top, 8)
      Spacer()
      ScrollView {
        VStack(spacing: 12) {
          settingsSection(items: [
            ("Restore purchases", "restore", restorePurchases, nil)
          ])
          
          settingsSection(items: [
            ("Rate our app", "star", showRateAlert, nil),
            ("Notifications", "bell", nil, notificationToggle),
            ("Share", "share", shareApp, nil),
            ("Contact us", "mail", sendEmail, nil)
          ])
          
          settingsSection(items: [
            ("Perms of Service", "perms", { openURL("https://docs.google.com/document/d/1GswJfATC1Ce4idZ3BPxQPzbdGOERuLafMsnofj7EnX8/edit?usp=sharing") }, nil),
            ("Privacy Policy", "privacy", { openURL("https://docs.google.com/document/d/19JuZ3Pxyz3oPI0yPRrzqFeMDqmtDm2HaBBi42R2sKhE/edit?usp=sharing") }, nil)
          ])
        }
        .padding(.horizontal, 16)
      }
    }
    .background(Color.black.edgesIgnoringSafeArea(.all))
    .navigationBarBackButtonHidden()
    .fullScreenCover(isPresented: $showPaywall) {
      PaywallView()
    }
  }
  
  private func settingsSection(items: [(String, String, (() -> Void)?, (() -> AnyView)?)] ) -> some View {
    VStack(spacing: 0) {
      ForEach(items.indices, id: \.self) { index in
        settingsRow(
          title: items[index].0,
          icon: items[index].1,
          action: items[index].2,
          trailing: items[index].3
        )
        
        if index < items.count - 1 {
          Divider()
            .background(ColorTokens.labelGray2)
        }
      }
    }
    .background(RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.1, green: 0.1, blue: 0.1)))
  }
  
  private func settingsRow(title: String, icon: String, action: (() -> Void)?, trailing: (() -> AnyView)? = nil) -> some View {
    Button(action: { action?() }) {
      HStack {
        Image(icon)
          .foregroundColor(.red)
          .frame(width: 24, height: 24)
        
        Text(title)
          .foregroundColor(.white)
          .font(.system(size: 16, weight: .medium))
        
        Spacer()
        
        if let trailingView = trailing?() {
          trailingView
        } else {
          Image(systemName: "chevron.right")
            .foregroundColor(.gray)
        }
      }
      .padding(.horizontal, 16)
      .frame(height: 60)
    }
  }
  
  private func notificationToggle() -> AnyView {
      AnyView(
          Toggle("", isOn: $notificationManager.isNotificationsEnabled)
              .labelsHidden()
              .onChange(of: notificationManager.isNotificationsEnabled) { newValue in
                  if newValue {
                      notificationManager.requestNotificationPermission()
                  } else {
                      notificationManager.disableNotifications()
                  }
              }
            .tint(ColorTokens.orange)
      )
  }

  private func showRateAlert() {
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
      SKStoreReviewController.requestReview(in: scene)
    } else {
      openAppStore()
    }
  }
  
  private func openAppStore() {
    if let url = URL(string: "https://apps.apple.com/us/app/id\(appID)?action=write-review") {
      UIApplication.shared.open(url)
    }
  }
  
  private func sendEmail() {
    let email = "support@example.com"
    let mailtoString = "mailto:\(email)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    if let url = URL(string: mailtoString) {
      UIApplication.shared.open(url)
    }
  }
  
  private func shareApp() {
    let appURL = URL(string: "https://apps.apple.com/us/app/id\(appID)")!
    let activityVC = UIActivityViewController(activityItems: [appURL], applicationActivities: nil)
    UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
  }
  
  private func restorePurchases() {
    Apphud.restorePurchases { subscriptions, nonRenewingPurchases, error in
      if let subscriptions = subscriptions, !subscriptions.isEmpty {
        dismiss()
      } else if let nonRenewingPurchases = nonRenewingPurchases, !nonRenewingPurchases.isEmpty {
        dismiss()
      } else {
        print("No active subscriptions found or error: \(error?.localizedDescription ?? "Unknown error")")
      }
    }
  }
  
  private func openURL(_ urlString: String) {
    if let url = URL(string: urlString) {
      UIApplication.shared.open(url)
    }
  }
}

#Preview {
  SettingsView()
}
