import SwiftUI
import UserNotifications

struct GeneratingView: View {
    @EnvironmentObject var tabManager: TabManager
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var avatarAPI = AvatarAPI.shared

    @State private var timeRemaining = 10
    @State private var notificationAllowed: Bool? = false
    @State private var showNotificationPermissionAlert = false
    @State private var navigateToProjectView = false
    @State private var navigateToResult = false        // ✅ 1) Добавили флаг навигации
    @State private var resultImageUrl: String?         // ✅ 2) Строка для ResultView

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
                            .background(Circle().fill(Color.black.opacity(0.3)))
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

                Text("\(timeRemaining) seconds left")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.top, 4)
                    .onAppear {
                        startCountdown()
                        checkNotificationStatus()
                        startGeneration()
                    }

                Spacer()

                Button(action: {
                    if notificationAllowed == nil {
                        requestNotificationPermission()
                    }
                }) {
                    Text("Get a notification")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(notificationAllowed == false ? GradientStyles.gradient3 : GradientStyles.gradient2)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
                .disabled(notificationAllowed == false)
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

            // ✅ 3) Навигация на ResultView
            .navigationDestination(isPresented: $navigateToResult) {
                // Передаём URL картинки в ResultView
                ResultView(imageUrl: resultImageUrl ?? "")
            }
        }
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationAllowed = settings.authorizationStatus == .authorized
            }
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

    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                if notificationAllowed == true {
                    sendNotification()
                }
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                notificationAllowed = granted
                if !granted {
                    showNotificationPermissionAlert = true
                }
            }
        }
    }

    private func startGeneration() {
        generationMethod(avatarAPI.userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ Генерация началась: \(response)")
                    self.jobId = response.jobId
                    self.generationStatus = response.status
                    self.isGodMode = response.isGodMode ?? false
                    startCheckingGenerationStatus()
                case .failure(let error):
                    print("❌ Ошибка генерации: \(error.localizedDescription)")
                }
            }
        }
    }

    private func startCheckingGenerationStatus() {
        guard let jobId = jobId else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
            checkGenerationStatus(jobId: jobId) { status, preview, resultUrl in
                DispatchQueue.main.async {
                    self.generationStatus = status
                    switch status {
                    case "COMPLETED":
                        self.previewURL = resultUrl
                        timer.invalidate()
                        saveProject()
                    case "NEW", "IN_QUEUE", "PROCESSING", "IN_PROGRESS":
                        print("⏳ Генерация: \(status)")
                    default:
                        print("❌ Неизвестный статус: \(status)")
                        timer.invalidate()
                    }
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

    private func saveProject() {
        guard let previewURL = previewURL else { return }

        let formattedDate = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        let placeholderProject = Project(
            id: UUID().uuidString,
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

        print("📌 Заглушка добавлена, ожидаем обновления изображения...")

        // ✅ Когда всё готово – переходим на ResultView
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Обновим проект и откроем ResultView
            ProjectManager.shared.updateProjectImage(projectId: placeholderProject.id, newImageUrl: previewURL)

            // Установим URL для ResultView
            resultImageUrl = previewURL
            // И попросим SwiftUI перейти на ResultView
            navigateToResult = true
        }
    }
}
