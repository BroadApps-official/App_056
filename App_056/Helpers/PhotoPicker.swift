import SwiftUI
import PhotosUI
import AVFoundation

struct PhotoPicker: UIViewControllerRepresentable {
  @Binding var selectedImages: [UIImage]
  @Binding var showImagePicker: Bool
  
  func makeUIViewController(context: Context) -> PHPickerViewController {
    var config = PHPickerConfiguration()
    config.selectionLimit = 50
    config.filter = .images
    
    let picker = PHPickerViewController(configuration: config)
    picker.delegate = context.coordinator
    return picker
  }
  
  func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    return Coordinator(self)
  }
  
  class Coordinator: NSObject, PHPickerViewControllerDelegate {
    let parent: PhotoPicker
    
    init(_ parent: PhotoPicker) {
      self.parent = parent
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      parent.selectedImages.removeAll()
      let group = DispatchGroup()
      
      for result in results {
        group.enter()
        result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
          DispatchQueue.main.async {
            if let uiImage = image as? UIImage {
              self.parent.selectedImages.append(uiImage)
            }
            group.leave()
          }
        }
      }
      
      group.notify(queue: .main) {
        self.parent.showImagePicker = false
      }
    }
  }
}

