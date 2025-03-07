import SwiftUI
import AdSupport
import AppTrackingTransparency
import CoreData
import ApphudSDK

@main
struct MyApp: App {
    @AppStorage("videoGenerationCount") private var videoGenerationCount = 0
    @AppStorage("appLaunchCount") private var appLaunchCount = 0
    @AppStorage("hasRatedApp") private var hasRatedApp = false
    @State private var showReviewSheet = false
    @StateObject var networkMonitor = NetworkMonitor.shared
    @StateObject var tabManager = TabManager()
    @StateObject var projectManager = ProjectManager.shared
  @StateObject private var generationManager = AvatarGenerationManager()

  init() {
     Apphud.start(apiKey: "app_GoQ3fPKcTQjSehk1DMKQAR3Cn1eUWk")
     Apphud.setDeviceIdentifiers(idfa: nil, idfv: UIDevice.current.identifierForVendor?.uuidString)
     fetchIDFA()
   }

    var body: some Scene {
        WindowGroup {
          HomeScreen()
                .environmentObject(tabManager)
                .environmentObject(projectManager)
                .environmentObject(networkMonitor)
                .environmentObject(generationManager)
                .onAppear {
                    appLaunchCount += 1
                    checkReviewConditions()
                }
                .sheet(isPresented: $showReviewSheet) {
                    ReviewRequestView()
                }
        }
    }

  func fetchIDFA() {
    if #available(iOS 14.5, *) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        ATTrackingManager.requestTrackingAuthorization { status in
          guard status == .authorized else { return }

          let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
          Apphud.setDeviceIdentifiers(idfa: idfa, idfv: UIDevice.current.identifierForVendor?.uuidString)
        }
      }
    }
  }

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "VideoDatabase")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                fatalError("❌ Unresolved error \(error)")
            }
        }
        return container
    }()

    private func checkReviewConditions() {
        if !hasRatedApp &&
            (videoGenerationCount == 3 || videoGenerationCount == 6 || appLaunchCount == 3) {
            showReviewSheet = true
        }
    }
}
