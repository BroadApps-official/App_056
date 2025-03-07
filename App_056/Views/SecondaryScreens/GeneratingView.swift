  import SwiftUI
  import UserNotifications

  struct GeneratingView: View {
      @EnvironmentObject var tabManager: TabManager
      @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var generationManager: AvatarGenerationManager
      @ObservedObject var avatarAPI = AvatarAPI.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
      @State private var timeRemaining = 10
//      @State private var notificationAllowed: Bool? = false
      @State private var showNotificationPermissionAlert = false
      @State private var navigateToProjectView = false
      @State private var navigateToResult = false
      @State private var resultImageUrl: String?

      @State private var jobId: String?
      @State private var generationStatus: String = "IN_QUEUE"
      @State private var previewURL: String?
      @State private var isGodMode: Bool = false
      @State private var timer: Timer?

      let isArtwork: Bool
      let gender: String
      let uploadedPhotos: [UIImage]
      let generationMethod: (String, @escaping (Result<GenerationData, Error>) -> Void) -> Void

      var body: some View {
          NavigationStack {
              VStack {
                  HStack {
                      Spacer()
                      Button(action: {
                          presentationMode.wrappedValue.dismiss()
                      }) {
                          Image(systemName: "xmark")
                              .foregroundColor(.white)
                              .font(.system(size: 20, weight: .bold))
                              .padding()
                              .background(Circle().fill(Color.gray.opacity(0.3)))
                      }
                      .padding()
                  }
                  Spacer()

                  RotatingArcView()
                      .frame(width: 80, height: 80)
                      .padding(.bottom, 16)

                  Text(generationStatus == "COMPLETED" ? "Generation Complete!" : "AI Generating ...")
                      .font(.system(size: 18, weight: .medium))
                      .foregroundColor(.white)
                      .onAppear {
                          startCountdown()
                          checkNotificationStatus()
                          startGeneration()
                      }

                  Spacer()

                    Button(action: {
                      if notificationManager.isNotificationsEnabled == false {
                            requestNotificationPermission()
                        }
                    }) {
                        Text("Get a notification")
                    }
                    .buttonStyle(NotificationButtonStyle(isDisabled: notificationManager.isNotificationsEnabled == true))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                    .disabled(notificationManager.isNotificationsEnabled == false)

              }
              .alert(isPresented: $showNotificationPermissionAlert) {
                  Alert(
                      title: Text("Notifications Disabled"),
                      message: Text("Please enable notifications in settings."),
                      dismissButton: .default(Text("OK"))
                  )
              }
              .navigationBarBackButtonHidden()
              .background(Color.black.edgesIgnoringSafeArea(.all))
              .navigationDestination(isPresented: $navigateToResult) {
                  ResultView(imageUrl: resultImageUrl ?? "")
              }
          }
      }

      // 🔹 Проверка статуса уведомлений
      private func checkNotificationStatus() {
          UNUserNotificationCenter.current().getNotificationSettings { settings in
              DispatchQueue.main.async {
                notificationManager.isNotificationsEnabled = settings.authorizationStatus == .authorized
              }
          }
      }

      private func startCountdown() {
          timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
              if timeRemaining > 0 {
                  timeRemaining -= 1
              } else {
                  timer.invalidate()
                  if notificationManager.isNotificationsEnabled == true {
                      sendNotification()
                  }
              }
          }
      }

      // ✅ 1) **Сначала добавляем плейсхолдер**
      private func savePlaceholderProject() {
          let formattedDate = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)

          let placeholderProject = Project(
              id: UUID().uuidString,
              imageName: "avatar-placeholder",
              date: formattedDate,
              isSelected: false,
              isLoading: true
          )

          self.jobId = placeholderProject.id 

          if isArtwork {
              ProjectManager.shared.addToArtwork(placeholderProject)
          } else {
              ProjectManager.shared.addToPreset(placeholderProject)
          }

          print("📌 Плейсхолдер добавлен: \(placeholderProject.id)")
      }

      // ✅ 2) **Старт генерации**
    private func startGeneration() {
      generationManager.isGenerating = true
        generationMethod(avatarAPI.userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let jobId = response.jobId
                    let formattedDate = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)

                    // 2) теперь создаём placeholder с id = jobId
                    let placeholderProject = Project(
                        id: jobId,
                        imageName: "avatar-placeholder",
                        date: formattedDate,
                        isSelected: false,
                        isLoading: true
                    )
                    if isArtwork {
                        ProjectManager.shared.addToArtwork(placeholderProject)
                    } else {
                        ProjectManager.shared.addToPreset(placeholderProject)
                    }

                    // 3) Сохраняем нужные поля
                    self.jobId = jobId
                    self.generationStatus = response.status
                    self.isGodMode = response.isGodMode ?? false

                    // 4) Запускаем проверку статуса
                    self.startCheckingGenerationStatus()

                case .failure(let error):
                    print("❌ Ошибка генерации: \(error.localizedDescription)")
                }
            }
        }
    }

    private func checkGenerationStatus(jobId: String, completion: @escaping (String, String?, String?) -> Void) {
            guard var urlComponents = URLComponents(string: "https://nextgenwebapps.shop/api/v1/services/status") else { return }
            urlComponents.queryItems = [
                URLQueryItem(name: "userId", value: avatarAPI.userId),
                URLQueryItem(name: "jobId", value: jobId)
            ]

            guard let url = urlComponents.url else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(AvatarAPI.bearerToken)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else { return }

                do {
                    let decodedResponse = try JSONDecoder().decode(GenerationStatusResponse.self, from: data)
                    let status = decodedResponse.data.status
                    let preview = decodedResponse.data.preview
                    let resultUrl = decodedResponse.data.resultUrl
                    completion(status, preview, resultUrl)
                } catch {
                    print("❌ Ошибка декодирования JSON: \(error)")
                }
            }.resume()
        }
      // ✅ 3) **Проверка статуса генерации**
      private func startCheckingGenerationStatus() {
          guard let jobId = jobId else {
              print("❌ Ошибка: `jobId` не установлен")
              return
          }

          timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
              self.checkGenerationStatus(jobId: jobId) { status, preview, resultUrl in
                  DispatchQueue.main.async { [self] in
                      self.generationStatus = status
                      switch status {
                      case "COMPLETED":
                          self.previewURL = resultUrl
                          timer.invalidate()
                          self.updateProjectImage()
                          self.sendNotification()
                          generationManager.isGenerating = false
                      default:
                          print("⏳ Генерация: \(status)")
                      }
                  }
              }
          }
      }

      // ✅ 4) **Обновление проекта в `ProjectManager`**
      private func updateProjectImage() {
          guard let projectId = jobId, let previewURL = previewURL else {
              print("❌ Ошибка: `projectId` или `previewURL` отсутствуют")
              return
          }

          // 🔹 Обновляем изображение в ProjectManager
          ProjectManager.shared.updateProjectImage(projectId: projectId, newImageUrl: previewURL)

          // 🔹 Устанавливаем URL результата для ResultView
          resultImageUrl = previewURL

          // 🔹 Безопасный переход на ResultView
          DispatchQueue.main.async {
              self.navigateToResult = true
          }
      }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "AI Generation Complete!"
        content.body = "Your AI-generated image is ready."
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "aiGenerationComplete", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
              notificationManager.isNotificationsEnabled = granted
                if !granted {
                    showNotificationPermissionAlert = true
                }
            }
        }
    }
  }

struct NotificationButtonStyle: ButtonStyle {
    var isDisabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                isDisabled
                ? Color.gray
                // Если не заблокировано, при нажатии немного притемняем
                : (configuration.isPressed ? Color.orange.opacity(0.7) : Color.orange)
            )
            .foregroundColor(.white)
            .clipShape(Capsule())
            .opacity(isDisabled ? 0.8 : 1)
    }
}
