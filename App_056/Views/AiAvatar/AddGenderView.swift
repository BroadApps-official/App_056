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
                .padding()
                .background(Circle().fill(Color.gray.opacity(0.3)))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Text("Your gender")
              .font(Typography.headline)
              .foregroundColor(.white)
            
              .frame(maxWidth: .infinity, alignment: .center)
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        
        Spacer().frame(height: 20)
        
        VStack(alignment: .leading, spacing: 5) {
          Text("Let's create your AI Avatar")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
          
          Text("Enter your gender")
            .font(.body)
            .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
        
        Spacer().frame(height: 20)
        
        VStack(spacing: 20) {
          GenderOptionButton(icon: "female", text: "Female", isSelected: selectedGender == "f") {
            selectedGender = "f"
          }
          
          GenderOptionButton(icon: "male", text: "Male", isSelected: selectedGender == "m") {
            selectedGender = "m"
          }
        }
        .padding(.horizontal, 20)
        
        Spacer()
        
        Button(action: {
          guard let gender = selectedGender else { return }
          generationManager.isGenerating = true
          uploadAvatar(gender: gender)
        }) {
          HStack {
            Text("Generate")
              .font(.system(size: 18, weight: .bold))
            
            Image(systemName: "sparkles")
              .font(.system(size: 20))
          }
          .frame(maxWidth: .infinity)
          .frame(height: 64)
          .background(selectedGender == nil ? GradientStyles.gradient3 : GradientStyles.gradient1)
          .foregroundColor(.white)
          .clipShape(Capsule())
        }
        .disabled(selectedGender == nil)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
      }
    }
    .navigationBarHidden(true)
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
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        Image(icon)
          .renderingMode(.template)
          .font(.system(size: 20))
          .foregroundColor(isSelected ? .white : .gray)
        
        Text(text)
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(isSelected ? .white : .gray)
        
        Spacer()
      }
      .padding()
      .frame(height: 90)
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

