import SwiftUI

struct AddGenderView: View {
  @Environment(\.dismiss) var dismiss
  @State private var selectedGender: String? = nil
  @ObservedObject var avatarAPI = AvatarAPI.shared
  @EnvironmentObject var tabManager: TabManager
  let uploadedPhotos: [UIImage]
  @State private var navigateToAiAvatarView = false
  @EnvironmentObject var generationManager: AvatarGenerationManager
  let onComplete: () -> Void
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Color.black.ignoresSafeArea()
        VStack(alignment: .leading) {
          HStack {
            ZStack {
              Button(action: {
                onComplete()
              }) {
                Image(systemName: "chevron.left")
                  .foregroundColor(.white)
                  .padding(geometry.size.width * 0.03)
                  .background(Circle().fill(Color.gray.opacity(0.3)))
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
              
              Text("Your gender")
                .font(.system(size: min(geometry.size.width * 0.05, 20), weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            }
          }
          .padding(.horizontal, geometry.size.width * 0.04)
          .padding(.top, geometry.size.height * 0.02)
          
          Spacer().frame(height: geometry.size.height * 0.02)
          
          VStack(alignment: .leading, spacing: geometry.size.height * 0.01) {
            Text("Let's create your AI Avatar")
              .font(.system(size: min(geometry.size.width * 0.06, 24), weight: .bold))
              .foregroundColor(.white)
            
            Text("Enter your gender")
              .font(.system(size: min(geometry.size.width * 0.04, 16)))
              .foregroundColor(.gray)
          }
          .padding(.horizontal, geometry.size.width * 0.05)
          
          Spacer().frame(height: geometry.size.height * 0.03)
          
          VStack(spacing: geometry.size.height * 0.02) {
            GenderOptionButton(icon: "female", text: "Female", isSelected: selectedGender == "f", geometry: geometry) {
              selectedGender = "f"
            }
            
            GenderOptionButton(icon: "male", text: "Male", isSelected: selectedGender == "m", geometry: geometry) {
              selectedGender = "m"
            }
          }
          .padding(.horizontal, geometry.size.width * 0.05)
          
          Spacer()
          
          Button(action: {
            guard let gender = selectedGender else { return }
            generationManager.isGenerating = true
            uploadAvatar(gender: gender)
          }) {
            HStack {
              Text("Generate")
                .font(.system(size: min(geometry.size.width * 0.045, 18), weight: .bold))
              
              Image(systemName: "sparkles")
                .font(.system(size: min(geometry.size.width * 0.05, 20)))
            }
            .frame(maxWidth: .infinity)
            .frame(height: geometry.size.height * 0.07)
            .background(selectedGender == nil ? GradientStyles.gradient3 : GradientStyles.gradient1)
            .foregroundColor(.white)
            .clipShape(Capsule())
          }
          .disabled(selectedGender == nil)
          .padding(.horizontal, geometry.size.width * 0.05)
          .padding(.bottom, geometry.size.height * 0.03)
        }
      }
      .navigationBarHidden(true)
    }
  }
  
  private func uploadAvatar(gender: String) {
    generationManager.isGenerating = true
    AvatarAPI.uploadAvatar(
      userId: avatarAPI.userId,
      gender: gender,
      photos: uploadedPhotos,
      preview: uploadedPhotos.first
    ) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let response):
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onComplete()
          }
        case .failure(let error):
          generationManager.isGenerating = false
        }
      }
    }
  }
}

struct GenderOptionButton: View {
  let icon: String
  let text: String
  let isSelected: Bool
  let geometry: GeometryProxy
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        Image(icon)
          .renderingMode(.template)
          .font(.system(size: min(geometry.size.width * 0.05, 20)))
          .foregroundColor(isSelected ? .white : .gray)
        
        Text(text)
          .font(.system(size: min(geometry.size.width * 0.045, 18), weight: .medium))
          .foregroundColor(isSelected ? .white : .gray)
        
        Spacer()
      }
      .padding(geometry.size.width * 0.04)
      .frame(height: geometry.size.height * 0.1)
      .frame(maxWidth: .infinity)
      .background(Color.black.opacity(0.2))
      .cornerRadius(20)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(isSelected ? Color.white : Color.gray, lineWidth: 2)
      )
    }
  }
}

#Preview {
  NavigationView {
    AddGenderView(
      uploadedPhotos: [],
      onComplete: {}
    )
    .environmentObject(TabManager())
    .environmentObject(AvatarGenerationManager())
  }
}

