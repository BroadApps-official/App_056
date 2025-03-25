import SwiftUI
import CoreData

struct PresetDetailView: View {
  let template: PresetTemplate
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var networkMonitor: NetworkMonitor
  @State private var showGeneratingView = false
  @State private var presetImage: UIImage?
  @State private var avatars: [Avatar] = []
  @State private var navigateToCreateAvatar = false
  @State private var selectedAvatarId: Int? = nil
  @State var presetId: Int
  @State private var showAlert = false

  var body: some View {
    NavigationStack {
      ZStack {
        Color.black.edgesIgnoringSafeArea(.all)

        VStack {
          ZStack(alignment: .topLeading) {
            if let presetImage = presetImage {
              Image(uiImage: presetImage)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.5)
                .offset(y: 80)
                .clipped()
                .overlay(
                  LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(1)]),
                    startPoint: .center,
                    endPoint: .bottom
                  )
                  .frame(height: 200),
                  alignment: .bottom
                )
                .edgesIgnoringSafeArea(.top)
            } else {
              AsyncImage(url: URL(string: template.preview)) { phase in
                switch phase {
                case .empty:
                  ProgressView()
                case .success(let image):
                  image
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.5)
                    .offset(y: 80)
                    .clipped()
                    .overlay(
                      LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(1)]),
                        startPoint: .center,
                        endPoint: .bottom
                      )
                      .frame(height: 200),
                      alignment: .bottom
                    )
                    .edgesIgnoringSafeArea(.top)
                case .failure:
                  Color.gray.frame(height: UIScreen.main.bounds.height * 0.55)
                @unknown default:
                  Color.gray.frame(height: UIScreen.main.bounds.height * 0.55)
                }
              }
            }

            Button(action: { dismiss() }) {
              Image(systemName: "chevron.left")
                .frame(width: 5, height: 12)
                .foregroundColor(.white)
                .padding()
                .background(Circle().fill(Color.gray.opacity(0.8)))
            }
            .padding(.leading, 16)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("15 photos will be generated for you")
              .font(.body)
              .foregroundColor(.gray)
          }
          .padding(.leading, 16)
          .padding(.bottom, 20)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, -70)

          VStack(alignment: .leading, spacing: 10) {
            Text("AI Avatar")
              .font(.headline)
              .foregroundColor(.white)
              .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 12) {
                if avatars.isEmpty {
                  Button(action: {
                    navigateToCreateAvatar = true
                  }) {
                    Circle()
                      .fill(Color.gray.opacity(0.5))
                      .frame(width: 60, height: 60)
                      .overlay(
                        Image(systemName: "plus")
                          .foregroundColor(.white)
                          .font(.system(size: 24))
                      )
                  }
                } else {
                  ForEach(avatars) { avatar in
                    ZStack {
                      AsyncImage(url: URL(string: avatar.preview ?? "")) { phase in
                        switch phase {
                        case .empty:
                          ProgressView()
                        case .success(let image):
                          image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                              Circle()
                                .stroke(selectedAvatarId == avatar.id ? ColorTokens.orange : Color.clear, lineWidth: 2)
                            )
                        case .failure:
                          Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 60, height: 60)
                        @unknown default:
                          Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 60, height: 60)
                        }
                      }
                      .onTapGesture {
                        selectedAvatarId = avatar.id
                      }
                    }
                  }
                }
              }
              .padding(.horizontal, 16)
            }
          }

          Spacer()

          Button(action: {
            guard let avatarId = selectedAvatarId else { return }

            AvatarAPI.shared.generatePhoto(userId: AvatarAPI.shared.userId, templateId: presetId, avatarId: avatarId) { result in
              DispatchQueue.main.async {
                switch result {
                case .success(let generationData):
                  showGeneratingView = true
                case .failure(let error):
                  print("❌ \(error.localizedDescription)")
                }
              }
            }
          }) {
            HStack {
              Text("Generate")
                .font(.system(size: 18, weight: .bold))

              Image(systemName: "sparkles")
                .font(.system(size: 20))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(selectedAvatarId == nil ? GradientStyles.gradient3 : GradientStyles.gradient1)
            .foregroundColor(.white)
            .clipShape(Capsule())
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 20)

          .disabled(selectedAvatarId == nil)
          .navigationDestination(isPresented: $showGeneratingView) {
            GeneratingView(
              isArtwork: false, gender: AvatarAPI.shared.gender,
              uploadedPhotos: [],
              generationMethod: { userId, completion in
                AvatarAPI.shared.generatePhoto(userId: userId, templateId: presetId, avatarId: selectedAvatarId ?? 0) { result in
                  completion(result)
                }
              }
            )
          }
        }
      }
      .navigationDestination(isPresented: $navigateToCreateAvatar) {
        CreateAIAvatarView(onComplete: {})
      }
      .onAppear {
        fetchAvatars()
        loadPresetImageFromCache()
      }
      .alert("No Internet Connection",
             isPresented: $showAlert,
             actions: {
        Button("OK") {}
      },
             message: {
        Text("Please check your internet settings.")
      })
      .navigationBarBackButtonHidden()
    }
  }

  private var presetImageView: some View {
    Group {
      if let presetImage = presetImage {
        Image(uiImage: presetImage)
          .resizable()
          .scaledToFill()
          .frame(width: UIScreen.main.bounds.width,
                 height: UIScreen.main.bounds.height * 0.5)
          .offset(y: 80)
          .clipped()
          .overlay(
            LinearGradient(
              gradient: Gradient(colors: [Color.clear, Color.black.opacity(1)]),
              startPoint: .center,
              endPoint: .bottom
            )
            .frame(height: 200),
            alignment: .bottom
          )
          .edgesIgnoringSafeArea(.top)
      } else {
        AsyncImage(url: URL(string: template.preview)) { phase in
          switch phase {
          case .empty:
            ProgressView()
          case .success(let image):
            image
              .resizable()
              .scaledToFill()
              .frame(width: UIScreen.main.bounds.width,
                     height: UIScreen.main.bounds.height * 0.5)
              .offset(y: 80)
              .clipped()
              .overlay(
                LinearGradient(
                  gradient: Gradient(colors: [Color.clear, Color.black.opacity(1)]),
                  startPoint: .center,
                  endPoint: .bottom
                )
                .frame(height: 200),
                alignment: .bottom
              )
              .edgesIgnoringSafeArea(.top)
          case .failure:
            Color.gray.frame(height: UIScreen.main.bounds.height * 0.55)
          @unknown default:
            Color.gray.frame(height: UIScreen.main.bounds.height * 0.55)
          }
        }
      }
    }
  }

  private func fetchAvatars() {
    AvatarAPI.shared.fetchAvatars { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let fetchedAvatars):
          self.avatars = fetchedAvatars
        case .failure(let error):
          print("❌ Error loading avatars: \(error.localizedDescription)")
        }
      }
    }
  }

  private func loadPresetImageFromCache() {
    let context = CoreDataManager.shared.context
    let fetchRequest: NSFetchRequest<CachedPreset> = CachedPreset.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "id == %d", template.id)

    do {
      let cachedPresets = try context.fetch(fetchRequest)
      if let cachedPreset = cachedPresets.first, let imageData = cachedPreset.imageData {
        presetImage = UIImage(data: imageData)
      }
    } catch {
      print("❌ \(error.localizedDescription)")
    }
  }
}
