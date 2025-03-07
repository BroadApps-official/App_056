import SwiftUI

struct CustomTextEditor: UIViewRepresentable {
  @Binding var text: String
  var textContainerInset: UIEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
  
  func makeUIView(context: Context) -> UITextView {
    let textView = UITextView()
    textView.backgroundColor = .clear
    textView.textColor = .white
    textView.font = UIFont.systemFont(ofSize: 17)
    textView.delegate = context.coordinator
    textView.textContainerInset = textContainerInset
    textView.isScrollEnabled = true
    return textView
  }
  
  func updateUIView(_ uiView: UITextView, context: Context) {
    uiView.text = text
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, UITextViewDelegate {
    var parent: CustomTextEditor
    
    init(_ parent: CustomTextEditor) {
      self.parent = parent
    }
    
    func textViewDidChange(_ textView: UITextView) {
      parent.text = textView.text
    }
  }
}
