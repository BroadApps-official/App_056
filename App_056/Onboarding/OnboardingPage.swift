import SwiftUI

struct OnboardingPage: View {
  let imageName: String
  let title: String
  let description: String
  let index: Int
  let widthPad: Bool
  let offset: CGFloat
  
  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        Image(imageName)
          .resizable()
          .scaledToFill()
          .frame(width: .infinity, height: widthPad ? .infinity : UIScreen.main.bounds.height * 0.84) 
          .clipped()
          .padding(.top, offset)
        
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
        VStack(spacing: 8) {
          Text(title)
            .font(Typography.largeTitle)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
          
          Text(description)
            .font(Typography.subheadline)
            .foregroundColor(ColorTokens.labelGray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
        }
        .padding(.top, UIScreen.main.bounds.height * 0.76)
      }
      .frame(maxHeight: .infinity, alignment: .top)
    }
    .background(.black)
  }
}

struct OnboardingPageOther: View {
  let imageName: String
  let title: String
  let description: String
  let index: Int
  
  var body: some View {
    ZStack {
      VStack(spacing: 20) {
        Image(imageName)
          .resizable()
          .scaledToFit()
          .frame(width: UIScreen.main.bounds.width - 40)
          .clipShape(RoundedRectangle(cornerRadius: 20))
        
        VStack(spacing: 8) {
          Text(title)
            .font(Typography.largeTitle)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
          
          Text(description)
            .font(Typography.subheadline)
            .foregroundColor(Color.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
        }
      }
      .frame(maxWidth: .infinity)
    }
    .background(Color.black.ignoresSafeArea())
  }
}

#Preview {
  OnboardingPage(
    imageName: "onboard5",
    title: "Endless Possibilities",
    description: "Design anything with AI",
    index: 0, widthPad: false, offset: 200
  )
}

