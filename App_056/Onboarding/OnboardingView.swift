import SwiftUI
import StoreKit

struct OnboardingView: View {
  @Binding var hasSeenOnboarding: Bool
  @State private var currentPage = 0
  @State private var showAlert = false
  @StateObject private var apiManager = AvatarAPI.shared
  
  let totalPages = 5
  
  var body: some View {
    VStack {
      GeometryReader { geometry in
        TabView(selection: $currentPage) {
          OnboardingPage(imageName: "onboard1", title: "Welcome to FLUX AI", description: "Craft visuals in seconds", index: 0, widthPad: true, offset: 0)
            .tag(0)
          OnboardingPageOther(imageName: "onboard2", title: "Endless Possibilities", description: "Design anything with AI", index: 1)
            .tag(1)
          OnboardingPageOther(imageName: "onboard3", title: "Your Vision, Realized", description: "AI turns your words into images", index: 2)
            .tag(2)
          OnboardingPage(imageName: "onboard4", title: "Your Feedback Matters", description: "Help us improve with your review", index: 3, widthPad: true, offset: 0)
            .tag(3)
          OnboardingPage(imageName: "onboard5", title: "Stay Informed!", description: "Enable notifications for updates", index: 4, widthPad: false, offset: 100)
            .tag(4)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height * 0.9)
      }
      
      Button(action: {
        if currentPage == 3 {
          requestReview()
        } else if currentPage == 4 {
          showAlert = true
        } else {
          withAnimation {
            currentPage += 1
          }
        }
      }) {
        Text("Next")
          .font(Typography.button)
          .frame(maxWidth: .infinity)
          .frame(height: 32)
          .padding()
          .background(GradientStyles.gradient2)
          .foregroundColor(.white)
          .cornerRadius(100)
          .padding(.horizontal, 20)
      }
      .padding(.bottom, 10)
      .padding(.top, -50)
      
      HStack(spacing: 8) {
        ForEach(0..<totalPages) { i in
          Circle()
            .frame(width: 8, height: 8)
            .foregroundColor(currentPage == i ? .white : .gray)
        }
      }
      .padding(.bottom, 40)
    }
    .background(.black)
    .edgesIgnoringSafeArea(.all)
    .onAppear {
      handleLoginAndSubscription()
    }
    .alert("Enable Notifications?", isPresented: $showAlert) {
      Button("Allow") {
        requestNotificationPermission()
      }
      Button("Not now", role: .cancel) {
        hasSeenOnboarding = true
      }
    } message: {
      Text("Stay up to date with new AI features and tips by enabling notifications.")
    }
  }
  
  private func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      DispatchQueue.main.async {
        hasSeenOnboarding = true
      }
    }
  }
  
  private func handleLoginAndSubscription() {
    if !apiManager.isLoggedIn {
      AvatarAPI.shared.loginUser { success in
        if success {
          let group = DispatchGroup()
          
          group.enter()
          apiManager.fetchPresets(gender: "f") { result in
            switch result {
            case .success(let presets):
              print("✅ load female presets: \(presets.count) шт.")
            case .failure(let error):
              print("❌: \(error.localizedDescription)")
            }
            group.leave()
          }
          
          group.enter()
          apiManager.fetchPresets(gender: "m") { result in
            switch result {
            case .success(let presets):
              print("✅ load male presets: \(presets.count) шт.")
            case .failure(let error):
              print("❌  \(error.localizedDescription)")
            }
            group.leave()
          }
          
          group.notify(queue: .main) {
            
            AvatarAPI.shared.setPaidPlan(productId: 22) { result in
              switch result {
              case .success(let response):
                AvatarAPI.shared.addAvatarGeneration { result in
                  switch result {
                  case .success(let response):
                    print("✅ Avatars added: \(response)")
                  case .failure(let error):
                    print("❌ Error avatars added: \(error.localizedDescription)")
                  }
                }
                
              case .failure(let error):
                print("❌  \(error.localizedDescription)")
              }
            }
          }
        } else {
          print("❌")
        }
      }
    }
  }
  
  private func requestReview() {
    if let windowScene = UIApplication.shared.connectedScenes
      .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
      SKStoreReviewController.requestReview(in: windowScene)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      withAnimation {
        currentPage += 1
      }
    }
  }
}

struct OnboardingView_Previews: PreviewProvider {
  static var previews: some View {
    OnboardingView(hasSeenOnboarding: .constant(false))
  }
}
