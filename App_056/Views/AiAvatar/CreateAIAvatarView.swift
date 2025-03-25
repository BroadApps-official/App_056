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
    ZStack {
      Color.black.ignoresSafeArea()
      
      VStack(alignment: .leading, spacing: 16) {
        HStack {
          Button(action: {
            dismiss()
          }) {
            Image(systemName: "chevron.left")
              .foregroundColor(.white)
              .padding()
              .background(Circle().fill(Color.gray.opacity(0.3)))
          }
          Spacer()
          Text("Create AI Avatar")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
          Spacer()
        }
        .padding(.horizontal, 16)
        
        Text("Pick from 10 to 50 of your best photos")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(.white)
          .padding(.horizontal, 16)
        
        Text("This is a one-time process")
          .font(.system(size: 14))
          .foregroundColor(.gray)
          .padding(.horizontal, 16)
        
        ForEach($instructions) { $instruction in
          InstructionRow(instruction: $instruction)
        }
        .padding(.horizontal, 16)
        
        Spacer()
        
        HStack {
          Spacer()
          Image("inst4")
          Spacer()
        }
        
        Spacer()
        
        NavigationLink(destination: GalleryPickerView(onComplete: onComplete)) {
          Text("Next")
            .font(.system(size: 18, weight: .bold))
            .frame(maxWidth: .infinity, maxHeight: 65)
            .background(GradientStyles.gradient1)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
      }
    }
    .navigationBarBackButtonHidden()
  }
}

struct InstructionRow: View {
  @Binding var instruction: Instruction
  
  var body: some View {
    HStack {
      Image(instruction.imageName)
        .resizable()
        .scaledToFill()
        .frame(width: 54, height: 56)
      
      Text(instruction.text)
        .font(.system(size: 16))
        .foregroundColor(.white)
    }
  }
}

