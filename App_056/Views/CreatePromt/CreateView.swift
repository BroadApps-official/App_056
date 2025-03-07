import SwiftUI

struct CreateView: View {
  @State private var selectedAvatarId: Int? = nil
  @State private var promptText: String = ""
  @State private var isEditing: Bool = false
  @State private var showAvatarSelection = false
  @State private var navigateToGenerating = false
  @ObservedObject private var avatarAPI = AvatarAPI.shared
  let editorWidth = UIScreen.main.bounds.width * 0.95
  @State private var avatars: [Avatar] = []
  @State private var navigateToAiAvatarView = false
  @EnvironmentObject var tabManager: TabManager
  @EnvironmentObject var networkMonitor: NetworkMonitor
  @State private var showAlert = false
  
  var isGenerateButtonActive: Bool {
    return !promptText.isEmpty
  }
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        Text("Art Creation")
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.top, 16)
        
        VStack(alignment: .leading, spacing: 12) {
          Text("AI Art")
            .font(.system(size: 18))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
          
          HStack {
            Text("AI Avatar")
              .font(.system(size: 16))
              .foregroundColor(.white)
            
            Image(systemName: "info.circle")
              .foregroundColor(.gray)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16)
          
          AvatarSelectionRow(
            avatars: avatars,
            selectedAvatarId: $selectedAvatarId,
            showAvatarSelection: { showAvatarSelection = true },
            navigateToAiAvatarView: $navigateToAiAvatarView
          )
          .environmentObject(tabManager)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("Enter Prompt")
              .font(.system(size: 16))
              .foregroundColor(.white)
            Image(systemName: "info.circle")
              .foregroundColor(.gray)
          }
          .padding(.horizontal, 26)
          
          ZStack(alignment: .topLeading) {
            if promptText.isEmpty && !isEditing {
              Text("What do you want to generate?")
                .foregroundColor(.gray)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
            }
            
            TextEditor(text: $promptText)
              .scrollContentBackground(.hidden)
              .background(Color.gray.opacity(0.2))
              .foregroundColor(.white)
              .frame(width: editorWidth, height: 200)
              .cornerRadius(16)
              .padding(.horizontal, 20)
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
              .font(.system(size: 18, weight: .bold))
            Image(systemName: "sparkles")
              .font(.system(size: 20))
          }
          .frame(maxWidth: .infinity)
          .frame(height: 64)
          .background(isGenerateButtonActive ? GradientStyles.gradient2 : GradientStyles.gradient3)
          .foregroundColor(.white)
          .clipShape(Capsule())
        }
        .padding(.bottom, 50)
        .padding(.horizontal, 20)
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
  
  var body: some View {
    HStack(spacing: 12) {
      ForEach(avatars.prefix(2), id: \.id) { avatar in
        AvatarPreview(avatar: avatar)
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
              .fill(Color.gray.opacity(0.3))
              .frame(width: 100, height: 100)
            Image(systemName: "plus")
              .font(.system(size: 24))
              .foregroundColor(.white)
          }
        }
      }
    }
    .padding(.horizontal, 16)
  }
}

struct AvatarPreview: View {
  let avatar: Avatar
  
  var body: some View {
    AsyncImage(url: URL(string: avatar.preview ?? "")) { phase in
      switch phase {
      case .empty:
        ProgressView()
      case .success(let image):
        image.resizable()
          .scaledToFill()
          .frame(width: 100, height: 100)
          .clipShape(Circle())
      case .failure:
        Circle()
          .fill(Color.gray.opacity(0.5))
          .frame(width: 100, height: 100)
      @unknown default:
        Circle()
          .fill(Color.gray.opacity(0.5))
          .frame(width: 100, height: 100)
      }
    }
  }
}

extension View {
  func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
  }
}
