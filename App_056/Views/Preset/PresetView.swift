import SwiftUI
import AVKit

struct PresetView: View {
  @ObservedObject private var apiManager = AvatarAPI.shared
  @ObservedObject private var subscriptionManager = SubscriptionManager.shared
  @EnvironmentObject var networkMonitor: NetworkMonitor
  @State private var showAlert = false
  @State private var showPaywall = false
  @State private var presets: [PresetCategory] = []
  @State private var isLoading = true
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        HStack {
          Text("AI Avatar")
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.white)
          Spacer()
          if !subscriptionManager.isSubscribed {
            Button(action: { showPaywall = true }) {
              HStack() {
                Image("crown")
                  .resizable()
                  .frame(width: 12, height: 10)
                  .foregroundColor(.white)
                
                Text("Pro")
                  .foregroundColor(.white)
                  .font(Typography.bodyMedium)
              }
              .padding(.horizontal, 5)
              .frame(width: 69, height: 32)
              .background(GradientStyles.gradient2)
              .clipShape(Capsule())
            }
          } else {
            Spacer().frame(width: 40)
          }
          
          NavigationLink(destination: SettingsView()) {
            Image(systemName: "gearshape")
              .foregroundColor(ColorTokens.orange)
              .padding(10)
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        
        ScrollView {
          VStack(spacing: 20) {
            ForEach(apiManager.presets.filter { !$0.templates.isEmpty }) { category in
              CategoryView(category: category)
            }
          }
        }
        .padding(.top, 30)
        .padding(.horizontal, 16)
        .padding(.bottom, 30)
      }
      .background(Color.black.edgesIgnoringSafeArea(.all))
      .fullScreenCover(isPresented: $showPaywall) {
        PaywallView()
      }
      .onAppear {
        if apiManager.presets.isEmpty {
          apiManager.fetchPresets(gender: apiManager.gender) { result in
            switch result {
            case .success(let presets):
              print("✅ Загружены пресеты: \(presets.count) шт.")
            case .failure(let error):
              print("❌ Ошибка загрузки пресетов: \(error.localizedDescription)")
            }
          }
        }
      }
      .onReceive(networkMonitor.$isConnected) { isConnected in
        if !isConnected {
          showAlert = true
        }
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
    .navigationBarBackButtonHidden()
  }
}

struct CategoryView: View {
  let category: PresetCategory
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(category.title)
          .font(.title2)
          .foregroundColor(.white)
          .bold()
        Spacer()
        NavigationLink(destination: CategoryDetailView(category: category)) {
          Text("See all")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.gray)
        }
      }
      .padding(.horizontal, 8)
      
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(category.templates.prefix(2)) { template in
            NavigationLink(destination: PresetDetailView(template: template, presetId: template.id)) {
              TemplateCard(template: template)
            }
          }
        }
        .padding(.horizontal, 8)
      }
    }
  }
}
