import SwiftUI

struct CategoryDetailView: View {
  let category: PresetCategory
  @Environment(\.dismiss) var dismiss
  
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
        Text(category.title)
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(.white)
        Spacer()
        Button(action: {}) {
          Image(systemName: "chevron.left")
            .opacity(0)
        }
        .frame(width: 40, height: 40)
      }
      .padding(.horizontal, 16)
      .padding(.top, 8)
      
      ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
          ForEach(category.templates) { template in
            NavigationLink(destination: PresetDetailView(template: template, presetId: template.id)) {
              TemplateCard(template: template)
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
      }
    }
    .background(Color.black.edgesIgnoringSafeArea(.all))
    .navigationBarBackButtonHidden(true)
  }
}

#Preview {
  let mockCategory = PresetCategory(
    id: 1,
    title: "Realism",
    preview: nil,
    isNew: false,
    templates: [
      PresetTemplate(id: 1, title: "Elite", preview: "https://example.com/image1.jpg", gender: "f", isEnabled: true),
      PresetTemplate(id: 2, title: "Queen", preview: "https://example.com/image2.jpg", gender: "f", isEnabled: true),
      PresetTemplate(id: 3, title: "Diva", preview: "https://example.com/image3.jpg", gender: "f", isEnabled: true),
      PresetTemplate(id: 4, title: "Model", preview: "https://example.com/image4.jpg", gender: "f", isEnabled: true),
      PresetTemplate(id: 5, title: "Rich woman", preview: "https://example.com/image5.jpg", gender: "f", isEnabled: true)
    ]
  )
  
  return CategoryDetailView(category: mockCategory)
}
