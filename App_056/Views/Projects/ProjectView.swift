import SwiftUI

struct ProjectView: View {
  @State private var selectedTab: String = "Preset"
  @State private var isEditing = false
  @State private var selectedProject: Project?
  @EnvironmentObject var tabManager: TabManager
  @ObservedObject private var projectManager = ProjectManager.shared
  @EnvironmentObject var networkMonitor: NetworkMonitor
  @State private var selectedImageUrl: ImageUrl?
  @State private var showAlert = false
  let columns = [
    GridItem(.flexible(), spacing: 16),
    GridItem(.flexible(), spacing: 16)
  ]

  var filteredProjects: [Project] {
    return selectedTab == "Preset" ? projectManager.presets : projectManager.artworks
  }

  var body: some View {
    NavigationStack {
      if #available(iOS 17.0, *) {
        ZStack {
          Color.black.ignoresSafeArea()
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("AI Avatar")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
              Spacer()

              if !filteredProjects.isEmpty {
                Button(action: { isEditing.toggle() }) {
                  Image(systemName: "trash")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                }
              }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            HStack {
              Button(action: { selectedTab = "Preset" }) {
                Text("Preset")
                  .font(.system(size: 18, weight: .semibold))
                  .foregroundColor(selectedTab == "Preset" ? .white : .gray)
                  .padding(.horizontal, 8)
              }

              Button(action: { selectedTab = "Artwork" }) {
                Text("Artwork")
                  .font(.system(size: 18, weight: .semibold))
                  .foregroundColor(selectedTab == "Artwork" ? .white : .gray)
                  .padding(.horizontal, 8)
              }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if filteredProjects.isEmpty {
              EmptyStateView(selectedTab: $selectedTab)
                .environmentObject(tabManager)
            } else {
              ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                  ForEach(Array(filteredProjects.enumerated()), id: \.element.id) { index, project in
                    ProjectItemView(
                      project: project,
                      isEditing: isEditing
                    ) {
                      if isEditing {
                        toggleProjectSelection(project)
                      } else {
                        selectedImageUrl = ImageUrl(url: project.imageName)
                      }
                    }
                  }
                }
                .padding(.horizontal, 16)
              }
              .padding(.vertical)
            }

            Spacer()

            if isEditing {
              HStack {
                Button(action: deleteSelectedProjects) {
                  Text("Delete")
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(filteredProjects.contains(where: { $0.isSelected }) ? Color.red : Color.gray)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .disabled(!filteredProjects.contains(where: { $0.isSelected }))
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
              }
            }
          }
          .navigationBarBackButtonHidden()
          .onAppear {
            projectManager.loadProjects()
          }
          .alert("No Internet Connection",
                 isPresented: $showAlert,
                 actions: {
            Button("OK") {}
          },
                 message: {
            Text("Please check your internet settings.")
          })
        }
        .navigationDestination(item: $selectedImageUrl) { imageUrl in
          ResultView(imageUrl: imageUrl.url)
            .environmentObject(projectManager)
            .environmentObject(tabManager)
        }
      } else {
      }
    }
  }

  private func toggleProjectSelection(_ project: Project) {
    if selectedTab == "Preset" {
      if let index = projectManager.presets.firstIndex(where: { $0.id == project.id }) {
        projectManager.presets[index].isSelected.toggle()
      }
    } else {
      if let index = projectManager.artworks.firstIndex(where: { $0.id == project.id }) {
        projectManager.artworks[index].isSelected.toggle()
      }
    }
  }

  private func deleteSelectedProjects() {
    let projectsToDelete = filteredProjects.filter { $0.isSelected }
    for project in projectsToDelete {
      projectManager.deleteProject(project)
    }
    isEditing = false
  }
}

struct ProjectItemView: View {
  var project: Project
  var isEditing: Bool
  var onSelect: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      ZStack {
        if project.isLoading {
          Image("avatar-placeholder")
            .resizable()
            .scaledToFill()
            .frame(width: (UIScreen.main.bounds.width - 48) / 2, height: 213)
            .cornerRadius(20)
            .clipped()
            .overlay(Color.black.opacity(0.4))
            .overlay(
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            )
        } else {
          if let url = URL(string: project.imageName) {
            AsyncImage(url: url) { phase in
              switch phase {
              case .empty:
                ProgressView()
                  .frame(width: (UIScreen.main.bounds.width - 48) / 2, height: 213)
              case .success(let image):
                image
                  .resizable()
                  .scaledToFill()
                  .frame(width: (UIScreen.main.bounds.width - 48) / 2, height: 213)
                  .cornerRadius(20)
                  .clipped()
              case .failure(_):
                Image("avatar-placeholder")
                  .resizable()
                  .scaledToFill()
                  .frame(width: (UIScreen.main.bounds.width - 48) / 2, height: 213)
                  .cornerRadius(20)
                  .clipped()
                  .overlay(Color.black.opacity(0.3))
              @unknown default:
                EmptyView()
              }
            }
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(project.isSelected ? ColorTokens.orange : Color.clear, lineWidth: 2)
            )
          } else {
            Image("avatar-placeholder")
              .resizable()
              .scaledToFill()
              .frame(width: (UIScreen.main.bounds.width - 48) / 2, height: 213)
              .cornerRadius(20)
              .clipped()
              .overlay(Color.black.opacity(0.3))
          }
        }

        if isEditing {
          VStack {
            Spacer()
            HStack {
              Spacer()
              Button(action: { onSelect() }) {
                Image(systemName: project.isSelected ? "checkmark.circle.fill" : "circle")
                  .foregroundColor(.red)
                  .padding(8)
              }
            }
          }
        }
      }
      Text(project.date)
        .font(.system(size: 14))
        .foregroundColor(.white.opacity(0.7))
    }
    .contentShape(Rectangle())
    .onTapGesture {
      if !isEditing {
        onSelect()
      }
    }
  }
}

struct EmptyStateView: View {
  @Binding var selectedTab: String
  @EnvironmentObject var tabManager: TabManager

  var body: some View {
    VStack(spacing: 12) {
      Spacer()
      Image("folder")
        .padding()

      Text("Nothing here yet")
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(.white)

      Text("Click ‘Create’ and start bringing ideas to life")
        .font(.system(size: 14))
        .foregroundColor(.gray)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)

      Spacer()

      Button(action: {
        if selectedTab == "Preset" {
          tabManager.selectedTab = .preset
        } else {
          tabManager.selectedTab = .create
        }
      }) {
        HStack {
          Text("Create")
            .font(.system(size: 18, weight: .bold))
          Image("stars")
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .background(GradientStyles.gradient1)
        .foregroundColor(.white)
        .clipShape(Capsule())
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 30)
    }
  }
}

struct Project: Identifiable, Hashable {
  let id: String
  var imageName: String
  let date: String
  var isSelected: Bool
  var isLoading: Bool = false
}


struct StoredProject {
  let id: UUID
  let imageName: String
  let date: String
  let isSelected: Bool

  init(from cachedProject: CachedProject) {
    self.id = UUID(uuidString: cachedProject.id ?? "") ?? UUID()
    self.imageName = cachedProject.imageName ?? ""
    self.date = cachedProject.date ?? ""
    self.isSelected = cachedProject.isSelected
  }
}

#Preview {
  ProjectView()
}
