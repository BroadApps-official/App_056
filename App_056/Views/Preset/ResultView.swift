import SwiftUI
import Photos

struct ResultView: View {
  let imageUrl: String?
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var projectManager: ProjectManager
  @EnvironmentObject var tabManager: TabManager

  var body: some View {
    VStack {
      HStack {
        Button(action: { dismiss() }) {
          Image(systemName: "chevron.left")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.white)
            .padding()
            .background(Circle().fill(Color.gray.opacity(0.3)))
        }
        Spacer()

        Button(action: { shareImage() }) {
          Image("share")
            .foregroundColor(.white)
            .font(.title2)
            .padding(10)
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 8)

      Spacer()

      if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
        AsyncImage(url: url) { phase in
          switch phase {
          case .empty:
            ProgressView()
              .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.height * 0.85)
          case .success(let image):
            image
              .resizable()
              .scaledToFit()
              .frame(width: UIScreen.main.bounds.width * 0.85)
              .cornerRadius(16)
          case .failure:
            Image("avatar-placeholder")
              .resizable()
              .scaledToFit()
              .frame(width: UIScreen.main.bounds.width * 0.85)
              .cornerRadius(16)
              .overlay(Color.black.opacity(0.3))
          @unknown default:
            EmptyView()
          }
        }
      } else {
        Image("avatar-placeholder")
          .resizable()
          .scaledToFit()
          .frame(width: UIScreen.main.bounds.width * 0.85)
          .cornerRadius(16)
          .overlay(Color.black.opacity(0.3))
      }

      Spacer()

      HStack(spacing: 32) {
        actionButton(icon: "trash", action: deleteImage)
        actionButton(icon: "replay", action: reloadImage)
        actionButton(icon: "download", action: saveImage)
      }
      .padding(.bottom, 30)
    }
    .background(Color.black.edgesIgnoringSafeArea(.all))
    .navigationBarBackButtonHidden()
  }

  private func actionButton(icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      ZStack {
        Image(icon)
          .foregroundColor(.red)
          .font(.title2)
          .frame(width: 60, height: 60)
      }
    }
  }

  private func deleteImage() {
    guard let imageUrl = imageUrl else { return }
    if let project = projectManager.presets.first(where: { $0.imageName == imageUrl }) {
      projectManager.deleteProject(project)
    } else if let project = projectManager.artworks.first(where: { $0.imageName == imageUrl }) {
      projectManager.deleteProject(project)
    }
    dismiss()
  }

  private func reloadImage() {
    guard let imageUrl = imageUrl else { return }
    if let project = projectManager.presets.first(where: { $0.imageName == imageUrl }) {
      tabManager.selectedTab = .preset
    } else if let project = projectManager.artworks.first(where: { $0.imageName == imageUrl }) {
      tabManager.selectedTab = .create
    }
    dismiss()
  }

  private func saveImage() {
    guard let imageUrl = imageUrl, let url = URL(string: imageUrl) else { return }
    downloadImage(from: url) { image in
      guard let image = image else { return }
      UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
  }

  private func shareImage() {
    guard let imageUrl = imageUrl, let url = URL(string: imageUrl) else { return }
    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootVC = windowScene.windows.first?.rootViewController {
      rootVC.present(activityVC, animated: true)
    }
  }

  private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, _ in
      if let data = data, let image = UIImage(data: data) {
        DispatchQueue.main.async {
          completion(image)
        }
      } else {
        DispatchQueue.main.async {
          completion(nil)
        }
      }
    }.resume()
  }
}
