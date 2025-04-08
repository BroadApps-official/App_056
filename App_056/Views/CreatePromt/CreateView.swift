import SwiftUI

struct CreateView: View {
  @State private var selectedAvatarId: Int? = nil
  @State private var promptText: String = ""
  @State private var isEditing: Bool = false
  @State private var showAvatarSelection = false
  @State private var navigateToGenerating = false
  @ObservedObject private var avatarAPI = AvatarAPI.shared
  let editorWidth = UIScreen.main.bounds.width * 0.95
  @State private var avatars: [Avatar]
  @State private var navigateToAiAvatarView = false
  @EnvironmentObject var tabManager: TabManager
  @EnvironmentObject var networkMonitor: NetworkMonitor
  @State private var showAlert = false
  @FocusState private var isTextEditorFocused: Bool

  init(avatars: [Avatar] = []) {
    _avatars = State(initialValue: avatars)
  }

  var isGenerateButtonActive: Bool {
    return !promptText.isEmpty
  }
  
  var body: some View {
    GeometryReader { geometry in
      NavigationStack {
        VStack(spacing: geometry.size.height * 0.02) {
          Text("Art Creation")
            .font(Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, geometry.size.height * 0.02)
          
          VStack(alignment: .leading, spacing: geometry.size.height * 0.015) {
            Text("AI Art")
              .font(.system(size: min(geometry.size.width * 0.045, 18)))
              .fontWeight(.bold)
              .foregroundColor(.white)
            
            HStack {
              Text("AI Avatar")
                .font(.system(size: min(geometry.size.width * 0.04, 16)))
                .foregroundColor(.white)
              
              ZStack {
                Circle()
                  .fill(Color.gray.opacity(0.3))
                  .frame(width: geometry.size.width * 0.06, height: geometry.size.width * 0.06)
                Text("!")
                  .font(.system(size: min(geometry.size.width * 0.035, 14), weight: .bold))
                  .foregroundColor(.gray)
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            AvatarSelectionRow(
              avatars: avatars,
              selectedAvatarId: $selectedAvatarId,
              showAvatarSelection: { showAvatarSelection = true },
              navigateToAiAvatarView: $navigateToAiAvatarView,
              geometry: geometry
            )
            .environmentObject(tabManager)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 20)
          
          VStack(alignment: .leading, spacing: geometry.size.height * 0.015) {
            HStack {
              Text("Enter Prompt")
                .font(.system(size: min(geometry.size.width * 0.04, 16)))
                .foregroundColor(.white)
              ZStack {
                Circle()
                  .fill(Color.gray.opacity(0.3))
                  .frame(width: geometry.size.width * 0.06, height: geometry.size.width * 0.06)
                Text("!")
                  .font(.system(size: min(geometry.size.width * 0.035, 14), weight: .bold))
                  .foregroundColor(.gray)
              }
            }
            .padding(.horizontal, geometry.size.width * 0.065)
            
            ZStack(alignment: .topLeading) {
              if promptText.isEmpty && !isEditing {
                Text("What do you want to generate?")
                  .foregroundColor(.gray)
                  .padding(.horizontal, geometry.size.width * 0.075)
                  .padding(.vertical, geometry.size.height * 0.015)
              }
              
              TextEditor(text: $promptText)
                .focused($isTextEditorFocused)
                .scrollContentBackground(.hidden)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.white)
                .frame(width: geometry.size.width * 0.95, height: geometry.size.height * 0.25)
                .cornerRadius(16)
                .padding(.horizontal, 10)
                .onTapGesture { isEditing = true }
                .onChange(of: promptText) { newValue in isEditing = !newValue.isEmpty }
            }
          }
          
          Spacer()
          
          Button(action: {
            hideKeyboard()
            navigateToGenerating = true
          }) {
            HStack {
              Text("Generate")
                .font(.system(size: min(geometry.size.width * 0.045, 18), weight: .bold))
              Image("stars")
                .font(.system(size: min(geometry.size.width * 0.05, 20)))
            }
            .frame(maxWidth: .infinity)
            .frame(height: geometry.size.height * 0.08)
            .background(GradientStyles.gradient1)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .blur(radius: isGenerateButtonActive ? 0 : 1)
            .opacity(isGenerateButtonActive ? 1 : 0.5)
          }
          .padding(.bottom, geometry.size.height * 0.06)
          .padding(.horizontal, geometry.size.width * 0.05)
          .navigationDestination(isPresented: $navigateToGenerating) {
            if let avatarId = selectedAvatarId, !promptText.isEmpty {
              GeneratingView(
                isArtwork: true, gender: "f",
                uploadedPhotos: [],
                generationMethod: { userId, completion in
                  generateInGodMode(userId: userId, avatarId: avatarId, prompt: promptText, completion: completion)
                }
              )
            } else {
              GeneratingView(
                isArtwork: true, gender: "f",
                uploadedPhotos: [],
                generationMethod: { userId, completion in
                  generateTextToImage(userId: userId, prompt: promptText, completion: completion)
                }
              )
            }
          }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onTapGesture { hideKeyboard() }
        .onAppear { fetchAvatarsIfNeeded() }
        .alert("No Internet Connection",
               isPresented: $showAlert,
               actions: {
          Button("OK") {}
        },
               message: {
          Text("Please check your internet settings.")
        })
      }
      .navigationBarBackButtonHidden()
    }
  }
  
  private func generateTextToImage(userId: String, prompt: String, completion: @escaping (Result<GenerationData, Error>) -> Void) {
    AvatarAPI.shared.generateTextToImage(userId: userId, prompt: prompt) { result in
      switch result {
      case .success(let response):
        let unifiedData = GenerationData(
          id: response.id,
          generationId: response.generationId,
          jobId: response.jobId,
          isGodMode: false,
          templateId: response.templateId,
          preview: response.preview,
          resultUrl: response.resultUrl,
          status: response.status,
          startedAt: response.startedAt,
          finishedAt: nil,
          isCoupled: nil,
          isTxt2Img: nil,
          isMarked: nil,
          mark: nil,
          seconds: nil,
          isCouple: nil
        )
        completion(.success(unifiedData))
        
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  
  private func generateInGodMode(userId: String, avatarId: Int, prompt: String, completion: @escaping (Result<GenerationData, Error>) -> Void) {
    AvatarAPI.shared.generateInGodMode(userId: userId, avatarId: avatarId, prompt: prompt) { result in
      switch result {
      case .success(let response):
        let unifiedData = GenerationData(
          id: response.id,
          generationId: response.generationId,
          jobId: response.jobId,
          isGodMode: true,
          templateId: response.templateId,
          preview: response.preview,
          resultUrl: response.resultUrl,
          status: response.status,
          startedAt: response.startedAt,
          finishedAt: response.finishedAt
        )
        completion(.success(unifiedData))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  private func selectedGenerationMethod() -> (String, @escaping (Result<GenerationData, Error>) -> Void) -> Void {
    if let avatarId = selectedAvatarId, !promptText.isEmpty {
      return { userId, completion in
        generateInGodMode(userId: userId, avatarId: avatarId, prompt: promptText, completion: completion)
      }
    } else {
      return { userId, completion in
        generateTextToImage(userId: userId, prompt: promptText, completion: completion)
      }
    }
  }
  
  private func fetchAvatarsIfNeeded() {
    avatarAPI.fetchAvatars { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let loadedAvatars):
          self.avatars = Array(loadedAvatars.prefix(2))
        case .failure(let error):
          print(error.localizedDescription)
        }
      }
    }
  }
}

struct AvatarSelectionRow: View {
  let avatars: [Avatar]
  @Binding var selectedAvatarId: Int?
  let showAvatarSelection: () -> Void
  @Binding var navigateToAiAvatarView: Bool
  @EnvironmentObject var tabManager: TabManager
  let geometry: GeometryProxy
  
  private var avatarSize: CGFloat {
    geometry.size.width * 0.2
  }
  
  var body: some View {
    HStack(spacing: 12) {
      if avatars.isEmpty {
        // Show only plus button when no avatars
        Button(action: {
          tabManager.selectedTab = .aiAvatar
        }) {
          ZStack {
            Circle()
              .fill(GradientStyles.gradient3)
              .frame(width: avatarSize, height: avatarSize)
            Image(systemName: "plus")
              .font(.system(size: min(geometry.size.width * 0.06, 24)))
              .foregroundColor(.white)
          }
        }
      } else {
        // Show avatars and plus button if needed
        ForEach(avatars.prefix(2), id: \.id) { avatar in
          AvatarPreview(avatar: avatar, size: avatarSize)
            .onTapGesture {
              selectedAvatarId = avatar.id
            }
            .overlay(
              RoundedRectangle(cornerRadius: 50)
                .stroke(selectedAvatarId == avatar.id ? ColorTokens.orange : Color.clear, lineWidth: 2)
            )
        }
        
        if avatars.count < 2 {
          Button(action: {
            tabManager.selectedTab = .aiAvatar
          }) {
            ZStack {
              Circle()
                .fill(GradientStyles.gradient3)
                .frame(width: avatarSize, height: avatarSize)
              Image(systemName: "plus")
                .font(.system(size: min(geometry.size.width * 0.06, 24)))
                .foregroundColor(.white)
            }
          }
        }
      }
    }
  }
}

struct AvatarPreview: View {
  let avatar: Avatar
  let size: CGFloat
  
  var body: some View {
    if let imageUrl = avatar.preview {
      CachedAvatarAsyncImage(url: imageUrl)
        .frame(width: size, height: size)
    } else {
      Circle()
        .fill(Color.gray.opacity(0.5))
        .frame(width: size, height: size)
        .overlay(
          Image(systemName: "photo")
            .foregroundColor(.white)
            .font(.system(size: size * 0.4))
        )
    }
  }
}

extension View {
  func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
  }
}

#Preview("No Avatars") {
  CreateView(avatars: [])
    .environmentObject(TabManager())
    .environmentObject(NetworkMonitor())
}

#Preview("One Avatar") {
  CreateView(avatars: [
    Avatar(
      id: 1,
      title: "Avatar 1",
      preview: "https://a2817cd1-d6a4-4a42-b52a-6fc6ffd26302.selcdn.net/preview/kSEgACgyZb8N0ZeigA0engdWfaD5eVQA5KhXLhF1.png",
      gender: "f",
      isActive: true
    )
  ])
    .environmentObject(TabManager())
    .environmentObject(NetworkMonitor())
}

#Preview("Two Avatars") {
  CreateView(avatars: [
    Avatar(
      id: 1,
      title: "Avatar 1",
      preview: "https://a2817cd1-d6a4-4a42-b52a-6fc6ffd26302.selcdn.net/preview/kSEgACgyZb8N0ZeigA0engdWfaD5eVQA5KhXLhF1.png",
      gender: "f",
      isActive: true
    ),
    Avatar(
      id: 2,
      title: "Avatar 2",
      preview: "https://a2817cd1-d6a4-4a42-b52a-6fc6ffd26302.selcdn.net/preview/kSEgACgyZb8N0ZeigA0engdWfaD5eVQA5KhXLhF1.png",
      gender: "f",
      isActive: true
    )
  ])
    .environmentObject(TabManager())
    .environmentObject(NetworkMonitor())
}
