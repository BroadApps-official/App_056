import SwiftUI
import StoreKit

struct ReviewRequestView: View {
  @Environment(\.dismiss) var dismiss
  
  @AppStorage("videoGenerationCount") private var videoGenerationCount = 0
  @AppStorage("appLaunchCount") private var appLaunchCount = 0
  @AppStorage("hasRatedApp") private var hasRatedApp = false
  
  private let appStoreURL = URL(string: "itms-apps://itunes.apple.com/us/app/flux-ai-avatar/id6742759369?action=write-review")!
  
  var body: some View {
    VStack(spacing: 20) {
      HStack {
          Button(action: { dismiss() }) {
              Image(systemName: "xmark")
                  .resizable()
                  .scaledToFit()
                  .frame(width: 12, height: 12)
                  .foregroundColor(.white)
                  .padding(12)
                  .background(Circle().fill(Color.white.opacity(0.2))) 
          }
          Spacer()
      }
      .padding(.leading, 16)



      Image("review")
        .resizable()
        .scaledToFit()
        .frame(width: 300, height: 300)
        .padding(.top, 10)

      Text("**Do you like our app?**")
        .font(Typography.largeTitle)
        .multilineTextAlignment(.center)
        .foregroundColor(.white)

      Text("Your opinion matters! Let us know what you think")
        .font(Typography.footnote)
        .multilineTextAlignment(.center)
        .foregroundColor(ColorTokens.labelGray)
        .padding(.horizontal, 40)
      Button(action: {
        openAppStoreReview()
      }) {
        Text("Rate")
          .font(Typography.bodyMedium)
          .frame(maxWidth: .infinity)
          .frame(height: 64)
          .background(GradientStyles.gradient1)
          .foregroundColor(.white)
          .cornerRadius(100)
          .padding(.horizontal, 20)
      }
      .padding(.top, 20)
      
      Spacer()
    }
    .background(.black)
  }
  
  private func openAppStoreReview() {
    hasRatedApp = true 
    if UIApplication.shared.canOpenURL(appStoreURL) {
      UIApplication.shared.open(appStoreURL)
    }
    dismiss()
  }
}

#Preview {
  ReviewRequestView()
}
