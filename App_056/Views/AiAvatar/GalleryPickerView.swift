import SwiftUI
import Photos

struct GalleryPickerView: View {
  @State private var selectedImages: [UIImage] = []
  @State private var showImagePicker = false
  @State private var navigateToAddGenderView = false
  @Environment(\.dismiss) var dismiss
  @ObservedObject private var subscriptionManager = SubscriptionManager.shared
  @EnvironmentObject var tabManager: TabManager
  let onComplete: () -> Void

  var body: some View {
    VStack {
      HStack {
        Button(action: { dismiss() }) {
          Image(systemName: "chevron.left")
            .foregroundColor(.white)
            .padding()
            .background(Circle().fill(Color.gray.opacity(0.3)))
        }
        Text("Selected photos")
          .font(Typography.headline)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity, alignment: .center)
      }
      .padding(.horizontal, 16)
      .padding(.top, 16)

      ScrollView {
        LazyVGrid(
          columns: [GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())],
          spacing: 10
        ) {
          ForEach(selectedImages, id: \.self) { image in
            Image(uiImage: image)
              .resizable()
              .scaledToFill()
              .frame(width: 100, height: 100)
              .clipShape(RoundedRectangle(cornerRadius: 8))
          }
        }
        .padding(.horizontal, 16)
      }

      Spacer()

      Button(action: {
        if selectedImages.count < 10 {
          requestPhotoAccess()
        } else {
          navigateToAddGenderView = true
        }
      }) {
        Text(selectedImages.count < 10 ? "Add photo" : "Continue")
          .font(.system(size: 18, weight: .bold))
          .frame(maxWidth: .infinity)
          .frame(height: 64)
          .background(selectedImages.count < 10 ? GradientStyles.gradient3 : GradientStyles.gradient1)
          .foregroundColor(.white)
          .clipShape(Capsule())
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 20)

      NavigationLink(
        destination: AddGenderView(uploadedPhotos: selectedImages, onComplete: onComplete),
        isActive: $navigateToAddGenderView
      ) {
        Text("")
          .opacity(0)
      }
    }
    .sheet(isPresented: $showImagePicker) {
      PhotoPicker(selectedImages: $selectedImages, showImagePicker: $showImagePicker)
    }
    .navigationBarBackButtonHidden()
  }

  private func requestPhotoAccess() {
    let status = PHPhotoLibrary.authorizationStatus()
    switch status {
    case .authorized:
      showImagePicker = true
    case .notDetermined:
      PHPhotoLibrary.requestAuthorization { newStatus in
        DispatchQueue.main.async {
          if newStatus == .authorized {
            showImagePicker = true
          }
        }
      }
    case .denied, .restricted, .limited:
      print("❌ ")
    @unknown default:
      break
    }
  }
}
