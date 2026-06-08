import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    private let appointments = DummyData.appointments
    private let stats = DummyData.stats

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                greeting
                WeatherWarningCard()
                TodayCard(appointments: appointments)
                MapCard(appointments: appointments)
                statsGrid
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {}) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.appTextPrimary)
                        .font(.system(size: 18, weight: .medium))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                notificationButton
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Subviews

    private var greeting: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(appState.greeting),")
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary)
                Text("\(appState.displayName) 👋")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appTextPrimary)
            }
            Spacer()
        }
    }

    private var notificationButton: some View {
        Button(action: {}) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .foregroundColor(.appTextPrimary)
                    .font(.system(size: 17))
                Circle()
                    .fill(Color.red)
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .offset(x: 5, y: -4)
            }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            ForEach(stats) { stat in
                StatsCard(item: stat)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}
