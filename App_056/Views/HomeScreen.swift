import SwiftUI

struct HomeScreen: View {
  @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
  @State private var showSplash = true
  @State private var showIntro = false
  
  var body: some View {
    ZStack {
      if showSplash {
        SplashScreen()
          .transition(.opacity)
      } else if !hasSeenOnboarding {
        OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
      } else {
        CustomTabBarView()
      }
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        withAnimation {
          showSplash = false
          if !hasSeenOnboarding {
            showIntro = true
          }
        }
      }
    }
  }
}

struct SplashScreen: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 20)
      Image("splash")
        .resizable()
        .frame(width: 100, height: 100)
        .cornerRadius(20)
    }
    .background(.black)
    .edgesIgnoringSafeArea(.all)
  }
}

struct IntroScreen: View {
  @Binding var showIntro: Bool
  
  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        Image("splashScreen")
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.9)
          .clipped()
        
        Spacer()
      }
      .overlay(
        LinearGradient(
          gradient: Gradient(colors: [
            Color.black.opacity(0.1),
            Color.black.opacity(1),
            Color.black.opacity(1)
          ]),
          startPoint: .center,
          endPoint: .bottom
        )
      )
      .background(.black)
      .ignoresSafeArea()
      
      VStack(spacing: 0) {
        VStack(spacing: 8) {
          Text("Welcome to FLUX AI")
            .font(Typography.largeTitle)
            .foregroundColor(.white)
          
          Text("Craft visuals in seconds")
            .font(Typography.subheadline)
            .foregroundColor(ColorTokens.labelGray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
        }
        .padding(.top, UIScreen.main.bounds.height * 0.63)
        Button(action: {
          withAnimation {
            showIntro = false
          }
        }) {
          Text("Next")
            .font(Typography.button)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .padding()
            .background(GradientStyles.gradient1)
            .foregroundColor(.white)
            .cornerRadius(100)
            .padding(.horizontal, 16)
        }
        .padding(.top, 32)
      }
      .frame(maxHeight: .infinity, alignment: .top)
    }
    .background(.black)
  }
}


struct MainAppView: View {
  var body: some View {
    Text("Main App Content")
      .font(.largeTitle)
  }
}

#Preview {
  HomeScreen()
}
