import SwiftUI

struct TemplateCard: View {
  let template: PresetTemplate
  
  var body: some View {
    VStack {
      CachedAsyncImage(url: template.preview)
        .scaledToFill()
        .frame(width: 169, height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
  }
}
