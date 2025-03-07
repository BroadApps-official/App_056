import SwiftUI

struct AIAvatarView: View {
  @ObservedObject private var avatarAPI = AvatarAPI.shared
  @EnvironmentObject var networkMonitor: NetworkMonitor
  @State private var selectedAvatarId: Int? = nil
  @State private var navigateToCreateAIAvatar = false
  @State private var showAlert = false
  @State private var avatars: [Avatar] = []
  let gender: String
  let uploadedPhotos: [UIImage]
  
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
                ForEach(avatars, id: \.id) { avatar in
                    AvatarItemView(
                        avatar: avatar,
                        isSelected: selectedAvatarId == avatar.id,
                        onSelect: {
                            selectedAvatarId = avatar.id
                        }
                    )
                }

                if avatars.count < 2 {
                    Button(action: {
                      navigateToCreateAIAvatar = true
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
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
        
        Spacer()
        
        if avatars.count > 0 && avatars.count < 3 {
          Button(action: {
            navigateToCreateAIAvatar = true
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
    .background(
      NavigationLink(
        destination: CreateAIAvatarView(),
        isActive: $navigateToCreateAIAvatar,
        label: { EmptyView() }
      )
      .frame(width: 0, height: 0)
      .opacity(0)
    )
    .onAppear {
      fetchAvatars()
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
          self.avatars = fetchedAvatars
          print("✅ Load \(avatars.count) avatars")
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
              .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
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
