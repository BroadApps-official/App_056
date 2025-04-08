import SwiftUI

struct CreateAIAvatarView: View {
  @Environment(\.dismiss) var dismiss
  @State private var instructions: [Instruction] = [
    Instruction(imageName: "inst1", text: "The face must be clearly visible"),
    Instruction(imageName: "inst2", text: "Photos must be of the same person"),
    Instruction(imageName: "inst3", text: "There must be nothing covering your face")
  ]
  @State private var navigateToGallery = false
  let onComplete: () -> Void
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(alignment: .leading, spacing: 0) {
          // Header
          HStack {
            Button(action: {
              dismiss()
            }) {
              Image(systemName: "chevron.left")
                .foregroundColor(.white)
                .padding(geometry.size.width * 0.03)
                .background(Circle().fill(Color.gray.opacity(0.3)))
            }
            Spacer()
            Text("Create AI Avatar")
              .font(.system(size: min(geometry.size.width * 0.05, 20), weight: .semibold))
              .foregroundColor(.white)
            Spacer()
          }
          .padding(.horizontal, geometry.size.width * 0.04)
          .padding(.top, geometry.size.height * 0.02)
          
          // Title
          Text("Pick from 10 to 50 of your best photos")
            .font(.system(size: min(geometry.size.width * 0.045, 18), weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, geometry.size.width * 0.04)
            .padding(.top, geometry.size.height * 0.03)
          
          // Subtitle
          Text("This is a one-time process")
            .font(.system(size: min(geometry.size.width * 0.035, 14)))
            .foregroundColor(.gray)
            .padding(.horizontal, geometry.size.width * 0.04)
            .padding(.top, geometry.size.height * 0.01)
          
          // Instructions
          VStack(alignment: .leading, spacing: geometry.size.height * 0.04) {
            ForEach($instructions) { $instruction in
              InstructionRow(instruction: $instruction, geometry: geometry)
            }
          }
          .padding(.horizontal, geometry.size.width * 0.04)
          .padding(.top, geometry.size.height * 0.03)
          
          Spacer()
          
          // Image
          HStack {
            Spacer()
            Image("inst4")
              .resizable()
              .scaledToFit()
              .frame(height: geometry.size.height * 0.35)
            Spacer()
          }
          
          Spacer()
          
          // Next Button
          NavigationLink(destination: GalleryPickerView(onComplete: onComplete)) {
            Text("Next")
              .font(.system(size: min(geometry.size.width * 0.045, 18), weight: .bold))
              .frame(maxWidth: .infinity)
              .frame(height: geometry.size.height * 0.07)
              .background(GradientStyles.gradient1)
              .foregroundColor(.white)
              .clipShape(Capsule())
              .padding(.horizontal, geometry.size.width * 0.04)
              .padding(.bottom, geometry.size.height * 0.02)
          }
        }
      }
      .navigationBarBackButtonHidden()
    }
  }
}

struct InstructionRow: View {
  @Binding var instruction: Instruction
  let geometry: GeometryProxy
  
  var body: some View {
    HStack(alignment: .center, spacing: geometry.size.width * 0.03) {
      Image(instruction.imageName)
        .resizable()
        .scaledToFill()
        .frame(width: geometry.size.width * 0.1, height: geometry.size.width * 0.1)
        .clipped()
      
      Text(instruction.text)
        .font(.system(size: min(geometry.size.width * 0.04, 16)))
        .foregroundColor(.white)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

#Preview {
  CreateAIAvatarView(onComplete: {})
}
