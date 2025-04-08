import SwiftUI

struct OnboardingPage: View {
  let imageName: String
  let title: String
  let description: String
  let index: Int
  let widthPad: Bool
  let offset: CGSize

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        VStack(spacing: 0) {
          Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: geometry.size.width, height: widthPad ? geometry.size.height : geometry.size.height * 0.9)
            .offset(offset)
            .clipped()
          
          Spacer()
        }
        .overlay(
          LinearGradient(
            gradient: Gradient(colors: [
              Color.black.opacity(0.1),
              Color.black.opacity(0.5),
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
          VStack(spacing: geometry.size.height * 0.01) {
            Text(title)
              .font(.system(size: min(geometry.size.width * 0.08, 34), weight: .bold))
              .foregroundColor(.white)
              .multilineTextAlignment(.center)
              .padding(.horizontal, geometry.size.width * 0.05)
            
            Text(description)
              .font(.system(size: min(geometry.size.width * 0.045, 18)))
              .foregroundColor(ColorTokens.labelGray)
              .multilineTextAlignment(.center)
              .padding(.horizontal, geometry.size.width * 0.05)
          }
          .padding(.top, geometry.size.height * 0.86)
        }
        .frame(maxHeight: .infinity, alignment: .top)
      }
      .background(.black)
    }
  }
}

struct OnboardingPageOther: View {
  let imageName: String
  let title: String
  let description: String
  let index: Int
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        VStack(spacing: geometry.size.height * 0.03) {
          Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: geometry.size.width - geometry.size.width * 0.1)
            .clipShape(RoundedRectangle(cornerRadius: min(geometry.size.width * 0.05, 20)))
          
          VStack(spacing: geometry.size.height * 0.01) {
            Text(title)
              .font(.system(size: min(geometry.size.width * 0.08, 34), weight: .bold))
              .foregroundColor(.white)
              .multilineTextAlignment(.center)
              .padding(.horizontal, geometry.size.width * 0.05)
            
            Text(description)
              .font(.system(size: min(geometry.size.width * 0.045, 18)))
              .foregroundColor(Color.gray)
              .multilineTextAlignment(.center)
              .padding(.horizontal, geometry.size.width * 0.05)
          }
        }
        .frame(maxWidth: .infinity)
      }
      .background(Color.black.ignoresSafeArea())
    }
  }
}

#Preview {
  OnboardingPage(
    imageName: "onboard5",
    title: "Endless Possibilities",
    description: "Design anything with AI",
    index: 0, widthPad: false, offset: CGSize(width: 0, height: 100)
  )
}

