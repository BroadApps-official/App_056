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
    GeometryReader { geometry in
      ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: geometry.size.height * 0.02) {
          // Header
          HStack {
            Spacer()
            Text("AI Avatar")
              .font(.system(size: min(geometry.size.width * 0.06, 24), weight: .semibold))
              .foregroundColor(.white)
            Spacer()
          }
          .padding(.top, geometry.size.height * 0.02)
          
          // Avatars ScrollView
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: geometry.size.width * 0.04) {
              if generationManager.isGenerating {
                PlaceholderAvatarView(size: geometry.size.width * 0.25)
              }
              ForEach(avatars, id: \.id) { avatar in
                AvatarItemView(
                  avatar: avatar,
                  isSelected: selectedAvatarId == avatar.id,
                  onSelect: {
                    selectedAvatarId = avatar.id
                  },
                  size: geometry.size.width * 0.25
                )
              }
              
              if totalAvatars < 2 {
                Button(action: {
                  isShowingCreationFlow = true
                }) {
                  ZStack {
                    Circle()
                      .fill(Color.gray.opacity(0.5))
                      .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.25)
                    Image(systemName: "plus")
                      .font(.system(size: min(geometry.size.width * 0.08, 32)))
                      .foregroundColor(.white)
                  }
                }
              }
            }
            .padding(.horizontal, geometry.size.width * 0.04)
            .padding(.top, geometry.size.height * 0.02)
          }
          
          Spacer()
          
          // Create New Button
          if totalAvatars > 0 && totalAvatars < 3 {
            Button(action: {
              isShowingCreationFlow = true
            }) {
              Text("Create New")
                .font(.system(size: min(geometry.size.width * 0.045, 18), weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: geometry.size.height * 0.07)
                .background(avatars.count < 2 ? GradientStyles.gradient1 : GradientStyles.gradient3)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .disabled(avatars.count >= 2)
            .padding(.horizontal, geometry.size.width * 0.05)
            .padding(.bottom, geometry.size.height * 0.05)
          }
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

struct AvatarItemView: View {
  let avatar: Avatar
  let isSelected: Bool
  let onSelect: () -> Void
  let size: CGFloat
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      if let imageUrl = avatar.preview {
        CachedAvatarAsyncImage(url: imageUrl)
          .frame(width: size, height: size)
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
          .frame(width: size, height: size)
          .onTapGesture {
            onSelect()
          }
      }
    }
  }
}

class AvatarGenerationManager: ObservableObject {
  @Published var isGenerating: Bool = false
}

struct PlaceholderAvatarView: View {
  let size: CGFloat
  
  var body: some View {
    ZStack {
      Circle()
        .fill(Color.gray.opacity(0.5))
        .frame(width: size, height: size)
      ProgressView()
        .scaleEffect(1.5)
    }
  }
}

#Preview("No Avatars") {
  AIAvatarView(
    gender: "f",
    uploadedPhotos: [],
    onComplete: {}
  )
  .environmentObject(NetworkMonitor())
  .environmentObject(AvatarGenerationManager())
}
