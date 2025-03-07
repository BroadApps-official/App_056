import SwiftUI

struct AIAvatarView: View {
  @ObservedObject private var avatarAPI = AvatarAPI.shared
  @EnvironmentObject var networkMonitor: NetworkMonitor
  @EnvironmentObject var generationManager: AvatarGenerationManager
  @State private var selectedAvatarId: Int? = nil
  @State private var navigateToCreateAIAvatar = false
  @State private var showAlert = false
  @State private var avatars: [Avatar] = []
  @State private var isShowingCreationFlow: Bool = false
  @State private var isGeneratingAvatar = false
  let gender: String
  let uploadedPhotos: [UIImage]
  @State private var timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
  private var totalAvatars: Int {
    avatars.count + (generationManager.isGenerating ? 1 : 0)
  }
  let onComplete: () -> Void
  
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      
      VStack {
        HStack {
          Spacer()
          Text("AI Avatar")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
          Spacer()
        }
        .padding(.top, 20)
        
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 16) {
            if generationManager.isGenerating {
              PlaceholderAvatarView()
            }
            ForEach(avatars, id: \.id) { avatar in
              AvatarItemView(
                avatar: avatar,
                isSelected: selectedAvatarId == avatar.id,
                onSelect: {
                  selectedAvatarId = avatar.id
                }
              )
            }
            
            if totalAvatars < 5 {
              Button(action: {
                isShowingCreationFlow = true
              }) {
                ZStack {
                  Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 100, height: 100)
                  Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                }
              }
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        
        
        Spacer()
        
        if totalAvatars > 0 && totalAvatars < 3 {
          Button(action: {
            isShowingCreationFlow = true
          }) {
            Text("Create New")
              .font(.system(size: 18, weight: .bold))
              .frame(maxWidth: .infinity)
              .frame(height: 64)
              .background(avatars.count < 2 ? GradientStyles.gradient2 : GradientStyles.gradient3)
              .foregroundColor(.white)
              .clipShape(Capsule())
          }
          .disabled(avatars.count >= 2)
          .padding(.horizontal, 20)
          .padding(.bottom, 50)
        }
      }
    }
    
    .fullScreenCover(isPresented: $isShowingCreationFlow) {
      NavigationStack {
        CreateAIAvatarView(onComplete: {
          isShowingCreationFlow = false
        })
      }
    }
    
    .onAppear {
      fetchAvatars()
    }
    .onReceive(timer) { _ in
      if generationManager.isGenerating {
        fetchAvatars()
      }
    }
    .alert("No Internet Connection",
           isPresented: $showAlert,
           actions: {
      Button("OK") {}
    },
           message: {
      Text("Please check your internet settings.")
    })
  }
  
  private func fetchAvatars() {
    avatarAPI.fetchAvatars { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let fetchedAvatars):
          let previousCount = self.avatars.count
          self.avatars = fetchedAvatars
          print("✅ Load \(self.avatars.count) avatars")
          if self.generationManager.isGenerating, fetchedAvatars.count == previousCount + 1 {
            self.generationManager.isGenerating = false
          }
          
        case .failure(let error):
          print("❌ Error loading avatar \(error.localizedDescription)")
        }
      }
    }
  }
}

struct AvatarItemView: View {
  let avatar: Avatar
  let isSelected: Bool
  let onSelect: () -> Void
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      if let imageUrl = avatar.preview {
        CachedAvatarAsyncImage(url: imageUrl)
          .overlay(
            Circle()
              .stroke(isSelected ? ColorTokens.orange : Color.clear, lineWidth: 3)
          )
          .onTapGesture {
            onSelect()
          }
      } else {
        Circle()
          .fill(Color.gray.opacity(0.5))
          .frame(width: 100, height: 100)
          .onTapGesture {
            onSelect()
          }
      }
    }
    .navigationBarBackButtonHidden()
  }
}

class AvatarGenerationManager: ObservableObject {
  @Published var isGenerating: Bool = false
}
struct PlaceholderAvatarView: View {
  var body: some View {
    ZStack {
      Circle()
        .fill(Color.gray.opacity(0.5))
        .frame(width: 100, height: 100)
      ProgressView()
    }
  }
}
