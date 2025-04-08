import SwiftUI
import Network

class NetworkMonitor: ObservableObject {
  
  static let shared = NetworkMonitor()
  @Published var isConnected: Bool = true
  
  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(label: "NetworkMonitorQueue")
  
  init() {
    monitor.pathUpdateHandler = { [weak self] path in
      DispatchQueue.main.async {
        self?.isConnected = (path.status == .satisfied)
      }
    }
    
    monitor.start(queue: queue)
  }
}
