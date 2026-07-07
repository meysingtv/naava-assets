import SwiftUI
import Charts

struct AuswertungenView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                kpiRow
                revenueChart
                orderStatusChart
                topCustomers
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .navigationTitle("Auswertungen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - KPI Row

    private var kpiRow: some View {
        HStack(spacing: 10) {
            kpiTile(label: "Umsatz YTD",    value: "94.800 €",  icon: "eurosign.circle.fill", color: .appGreen)
            kpiTile(label: "Ø Auftragswert",value: "3.160 €",   icon: "chart.line.uptrend.xyaxis", color: .appBlue)
            kpiTile(label: "Aufträge",       value: "30",        icon: "briefcase.fill",        color: .appOrange)
        }
    }

    private func kpiTile(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Revenue Chart

    private var revenueChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monatsumsatz")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    Text("Letzte 6 Monate")
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
                Text("2026")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appTextSecondary)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.appBackground)
                    .cornerRadius(8)
            }

            Chart(monthlyData) { item in
                BarMark(
                    x: .value("Monat", item.month),
                    y: .value("Umsatz", item.revenue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appBlue, Color.appBlue.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(6)
                .annotation(position: .top) {
                    Text("\(Int(item.revenue / 1000))k")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                }
            }
            .chartYScale(domain: 0...25000)
            .chartYAxis {
                AxisMarks(values: [0, 5000, 10000, 15000, 20000, 25000]) { val in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.2))
                    AxisValueLabel {
                        if let v = val.as(Double.self) {
                            Text("\(Int(v/1000))k")
                                .font(.system(size: 9))
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10))
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Order Status Chart

    private var orderStatusChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Auftragsstatus")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.appTextPrimary)

            HStack(alignment: .center, spacing: 24) {
                Chart(statusData) { item in
                    SectorMark(
                        angle: .value("Anzahl", item.count),
                        innerRadius: .ratio(0.56),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(statusData) { item in
                        HStack(spacing: 8) {
                            Circle().fill(item.color).frame(width: 10, height: 10)
                            Text(item.label)
                                .font(.system(size: 13))
                                .foregroundColor(.appTextPrimary)
                            Spacer()
                            Text("\(item.count)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Top Customers

    private var topCustomers: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Top Kunden")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 10) {
                ForEach(Array(topCustomerData.enumerated()), id: \.offset) { i, item in
                    HStack(spacing: 12) {
                        Text("\(i + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.appTextSecondary)
                            .frame(width: 18)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.appBackground).frame(height: 5)
                                    Capsule()
                                        .fill(Color.appBlue)
                                        .frame(width: geo.size.width * item.share, height: 5)
                                }
                            }
                            .frame(height: 5)
                        }

                        Text(item.revenue)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.appTextPrimary)
                            .frame(width: 72, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Data

    private struct MonthRevenue: Identifiable {
        let id = UUID(); let month: String; let revenue: Double
    }
    private let monthlyData = [
        MonthRevenue(month: "Jan", revenue: 8200),
        MonthRevenue(month: "Feb", revenue: 11500),
        MonthRevenue(month: "Mär", revenue: 9800),
        MonthRevenue(month: "Apr", revenue: 15200),
        MonthRevenue(month: "Mai", revenue: 13400),
        MonthRevenue(month: "Jun", revenue: 18700),
    ]

    private struct StatusData: Identifiable {
        let id = UUID(); let label: String; let count: Int; let color: Color
    }
    private let statusData = [
        StatusData(label: "In Arbeit",     count: 5,  color: .appGreen),
        StatusData(label: "Offen",         count: 8,  color: .appOrange),
        StatusData(label: "Abgeschlossen", count: 12, color: .appBlue),
        StatusData(label: "Abgerechnet",   count: 5,  color: .appPurple),
    ]

    private struct CustomerData: Identifiable {
        let id = UUID(); let name: String; let revenue: String; let share: CGFloat
    }
    private let topCustomerData = [
        CustomerData(name: "Familie Müller",   revenue: "18.900 €", share: 1.0),
        CustomerData(name: "Maier & Söhne",    revenue: "14.200 €", share: 0.75),
        CustomerData(name: "Fa. Schmidt GmbH", revenue: "11.800 €", share: 0.62),
        CustomerData(name: "Claudia Weber",    revenue: "8.400 €",  share: 0.44),
        CustomerData(name: "Thomas Bauer",     revenue: "5.600 €",  share: 0.30),
    ]
}

#Preview {
    NavigationStack { AuswertungenView() }
}
