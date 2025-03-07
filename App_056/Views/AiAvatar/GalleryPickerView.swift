import SwiftUI
import PhotosUI

struct GalleryPickerView: View {
  @State private var selectedImages: [UIImage] = []
  @State private var showImagePicker = false
  @State private var showPaywall = false
  @State private var navigateToAddGenderView = false
  @Environment(\.dismiss) var dismiss
  
  @ObservedObject private var subscriptionManager = SubscriptionManager.shared
  
  var body: some View {
    NavigationStack {
      ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
          HStack {
            Button(action: {
              dismiss()
            }) {
              Image(systemName: "chevron.left")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .padding(10)
            }
            Spacer()
            Text("Selected photos")
              .font(Typography.headline)
              .foregroundColor(.white)
            Spacer()
          }
          .padding(.horizontal, 16)
          .padding(.top, 16)
          
          ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
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
          
          NavigationLink(destination: AddGenderView(uploadedPhotos: selectedImages), isActive: $navigateToAddGenderView) {
            EmptyView()
          }
          
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
              .background(selectedImages.count < 10 ? GradientStyles.gradient3 : GradientStyles.gradient2)
              .foregroundColor(.white)
              .clipShape(Capsule())
          }
          .padding(.horizontal, 16)
          .padding(.bottom, 20)
        }
      }
      .sheet(isPresented: $showImagePicker) {
        PhotoPicker(selectedImages: $selectedImages, showImagePicker: $showImagePicker)
      }
      .navigationBarBackButtonHidden()
    }
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
      print("❌ Доступ к фото запрещен")
    @unknown default:
      break
    }
  }
}
