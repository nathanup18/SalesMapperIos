import SwiftUI

// MARK: - Main View
struct StatisticsView: View {
    @ObservedObject var markerViewModel: MarkerViewModel
    @State private var selectedTimeframe: StatisticsTimeframe = .weekly
    @State private var showingTeamView = false
    @State private var selectedTeam: Int?
    @State private var selectedSalesman: String?
    @State private var isAdmin = true // TODO: Get from user profile
    @Environment(\.dismiss) private var dismiss
    
    // Initializer to receive MarkerViewModel from parent
    init(markerViewModel: MarkerViewModel) {
        self.markerViewModel = markerViewModel
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Connection Status
                    StatisticsConnectionCard(markerVM: markerViewModel)
                    
                    // Timeframe Selector - moved directly under connection status
                    TimeframeSelectorView(selectedTimeframe: $selectedTimeframe)
                    
                    // Main Stats Cards (Large 2x2 Grid)
                    LargeActivitySummaryView(
                        markers: filteredMarkers,
                        timeframe: selectedTimeframe
                    )
                    
                    // Performance Metrics Cards (Large, Prominent)
                    EnhancedPerformanceMetricsView(
                        markers: filteredMarkers,
                        timeframe: selectedTimeframe
                    )
                    
                    // Visual Divider
                    Divider()
                        .padding(.horizontal)
                    
                    // Charts Section - Now respects the selected timeframe!
                    ChartsView(
                        markers: filteredMarkers,
                        timeframe: selectedTimeframe,
                        markerViewModel: markerViewModel
                    )
                    
                    // Admin Section (All-time data - not affected by selector)
                    if isAdmin {
                        AdminSection()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Load data when view appears
                print("📊 StatisticsView appeared - Current timeframe: \(selectedTimeframe)")
                print("📊 Filtered markers count: \(filteredMarkers.count)")
                
                // Test all timeframes
                markerViewModel.testTimeframeFiltering()
            }
            .onChange(of: selectedTimeframe) { newTimeframe in
                print("📊 Timeframe changed to: \(newTimeframe)")
                print("📊 New filtered markers count: \(filteredMarkers.count)")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingTeamView) {
                TeamDetailView(
                    teamNumber: selectedTeam,
                    timeframe: selectedTimeframe,
                    markerViewModel: markerViewModel
                )
            }
        }
    }
    
    private var filteredMarkers: [Marker] {
        markerViewModel.getMarkers(
            for: selectedTimeframe,
            salesmanName: selectedSalesman,
            teamNumber: selectedTeam
        )
    }
    
    @ViewBuilder
    private func AdminSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Team Performance")
                .font(.title2)
                .fontWeight(.bold)
            
            TeamLeaderboardView(timeframe: .allTime, onTeamTap: { teamNumber in
                selectedTeam = teamNumber
                showingTeamView = true
            }, markerViewModel: markerViewModel)
        }
    }
}


// MARK: - Large Activity Summary View (for detailed analytics)
struct LargeActivitySummaryView: View {
    let markers: [Marker]
    let timeframe: StatisticsTimeframe
    
    private var soldCount: Int {
        markers.filter { $0.status == .sold }.count
    }
    
    private var notInterestedCount: Int {
        markers.filter { $0.status == .notInterested }.count
    }
    
    private var notHomeCount: Int {
        markers.filter { $0.status == .notHome }.count
    }
    
    private var totalDoors: Int {
        markers.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Always show the cards, even with zero values for better UX
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 18) {
                LargeActivityCard(
                    title: "Sold",
                    value: "\(soldCount)",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                LargeActivityCard(
                    title: "Not Int.",
                    value: "\(notInterestedCount)",
                    color: .red,
                    icon: "xmark.circle.fill"
                )
                
                LargeActivityCard(
                    title: "Not Home",
                    value: "\(notHomeCount)",
                    color: .orange,
                    icon: "clock.fill"
                )
                
                LargeActivityCard(
                    title: "Total",
                    value: "\(totalDoors)",
                    color: .blue,
                    icon: "house.fill"
                )
            }
            .padding(.horizontal)
            
            // Show debug information and data availability message
            VStack(spacing: 4) {
                if markers.isEmpty {
                    Text("No data available for the selected time period")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Showing \(markers.count) markers for \(timeframe.rawValue.lowercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Debug info (remove in production)
                #if DEBUG
                Text("Debug: \(markers.count) total markers loaded")
                    .font(.caption2)
                    .foregroundColor(.orange)
                #endif
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Large Activity Card Component (matches home page design)
struct LargeActivityCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Circular icon background (10% larger)
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Large number (12.5% larger)
                Text(value)
                    .font(.system(size: 40.5, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            // Title at bottom left (12.5% larger)
            HStack {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
            }
        }
        .padding(22)
        .frame(height: 121)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.15), lineWidth: 2)
                )
        )
        .shadow(color: color.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Compact Stats Cards View
struct CompactStatsCardsView: View {
    let markers: [Marker]
    let timeframe: StatisticsTimeframe
    
    private var soldCount: Int {
        markers.filter { $0.status == .sold }.count
    }
    
    private var notInterestedCount: Int {
        markers.filter { $0.status == .notInterested }.count
    }
    
    private var notHomeCount: Int {
        markers.filter { $0.status == .notHome }.count
    }
    
    private var totalDoors: Int {
        markers.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Activity Summary")
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                CompactStatCard(
                title: "Sold",
                value: "\(soldCount)",
                color: .green,
                    icon: "checkmark.circle.fill"
            )
            
                CompactStatCard(
                title: "Not Int.",
                value: "\(notInterestedCount)",
                color: .red,
                    icon: "xmark.circle.fill"
            )
            
                CompactStatCard(
                title: "Not Home",
                value: "\(notHomeCount)",
                color: .orange,
                    icon: "clock.fill"
            )
            
                CompactStatCard(
                title: "Total",
                value: "\(totalDoors)",
                color: .blue,
                    icon: "house.fill"
                )
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Compact Stat Card Component
struct CompactStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            // Circular icon background (like home screen)
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Large number (like home screen)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Title
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Enhanced Charts View with Filtering
struct ChartsView: View {
    let markers: [Marker]
    let timeframe: StatisticsTimeframe
    @ObservedObject var markerViewModel: MarkerViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // New Enhanced Hourly Chart
            HourlyStatsChart(
                timeframe: timeframe,
                markerViewModel: markerViewModel
            )
            
            // New Enhanced Daily Chart
            DailyStatsChart(
                timeframe: timeframe,
                markerViewModel: markerViewModel
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Hourly Statistics Chart
struct HourlyStatsChart: View {
    let timeframe: StatisticsTimeframe
    @ObservedObject var markerViewModel: MarkerViewModel
    
    // Filtering state
    @State private var startHour: Int = 9
    @State private var endHour: Int = 17
    @State private var selectedTeam: Int?
    @State private var selectedSalesman: String?
    @State private var showFilters = false
    
    private var hourlyData: [HourlyData] {
        markerViewModel.getHourlyMarkerData(
            hourRange: startHour...endHour,
            for: timeframe,
            salesmanName: selectedSalesman,
            teamNumber: selectedTeam
        )
    }
    
    private var maxCount: Int {
        hourlyData.map(\.count).max() ?? 1
    }
    
    private func hourLabel(for hour: Int) -> String {
        hour == 0 ? "12AM" : hour < 12 ? "\(hour)AM" : hour == 12 ? "12PM" : "\(hour-12)PM"
    }
    
    private var startHourMenu: some View {
        Menu {
            ForEach(0...23, id: \.self) { hour in
                Button(hourLabel(for: hour)) {
                    startHour = hour
                }
            }
        } label: {
            HStack {
                Text(hourLabel(for: startHour))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
        }
    }
    
    private var endHourMenu: some View {
        Menu {
            ForEach(startHour...23, id: \.self) { hour in
                Button(hourLabel(for: hour)) {
                    endHour = hour
                }
            }
        } label: {
            HStack {
                Text(hourLabel(for: endHour))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
        }
    }
    
    private var teamMenu: some View {
        Menu {
            Button("All Teams") {
                selectedTeam = nil
            }
            
            ForEach(markerViewModel.getTeamNumbers(), id: \.self) { team in
                Button("Team \(team)") {
                    selectedTeam = team
                }
            }
        } label: {
            menuLabel(text: selectedTeam == nil ? "All Teams" : "Team \(selectedTeam!)")
        }
    }
    
    private var salesmanMenu: some View {
        Menu {
            Button("All Salesmen") {
                selectedSalesman = nil
            }
            
            ForEach(markerViewModel.getSalesmen(for: selectedTeam), id: \.self) { salesman in
                Button(salesman) {
                    selectedSalesman = salesman
                }
            }
        } label: {
            menuLabel(text: selectedSalesman ?? "All Salesmen")
        }
    }
    
    private func menuLabel(text: String) -> some View {
        HStack {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        )
    }
    
    private var hourlyFiltersView: some View {
        VStack(spacing: 16) {
            // Hour range pickers
            HStack(spacing: 16) {
                // Start Hour Filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start Hour")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    startHourMenu
                }
                
                // End Hour Filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("End Hour")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    endHourMenu
                }
            }
            
            // Team and salesman filters
            HStack(spacing: 16) {
                // Team Filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("Team")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    teamMenu
                }
                
                // Salesman Filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("Salesman")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    salesmanMenu
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with filter toggle
            HStack {
                VStack(alignment: .leading) {
                    Text("Hourly Activity")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(startHour == 0 ? "12AM" : startHour < 12 ? "\(startHour)AM" : startHour == 12 ? "12PM" : "\(startHour-12)PM") - \(endHour == 0 ? "12AM" : endHour < 12 ? "\(endHour)AM" : endHour == 12 ? "12PM" : "\(endHour-12)PM")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showFilters.toggle() 
                    }
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(showFilters ? .white : .blue)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(showFilters ? Color.blue : Color.clear)
                        )
                }
            }
            
            // Filter controls (shown when toggled)
            if showFilters {
                hourlyFiltersView
            }
            
                        // Chart visualization
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 8) {
                    // Add leading spacer for centering when needed
                    if hourlyData.count < 8 {
                        Spacer()
                    }
                    
                    ForEach(hourlyData) { data in
                        VStack(spacing: 6) {
                            // Bar with count label
                            VStack {
                                if data.count > 0 {
                                    Text("\(data.count)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(data.count > 0 ? Color.blue.opacity(0.8) : Color.gray.opacity(0.3))
                                    .frame(
                                        width: 28,
                                        height: max(4, CGFloat(data.count) / CGFloat(maxCount) * 120)
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: data.count)
                            }
                            
                            // Hour label
                            Text(data.label)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    // Add trailing spacer for centering when needed
                    if hourlyData.count < 8 {
                        Spacer()
                    }
        }
        .padding(.horizontal)
    }
    
            // Summary stats
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Markers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(hourlyData.reduce(0) { $0 + $1.count })")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Peak Hour")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let peak = hourlyData.max(by: { $0.count < $1.count }) {
                        Text(peak.label)
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Daily Statistics Chart
struct DailyStatsChart: View {
    let timeframe: StatisticsTimeframe
    @ObservedObject var markerViewModel: MarkerViewModel
    
    // Filtering state
    @State private var selectedTeam: Int?
    @State private var selectedSalesman: String?
    @State private var showFilters = false
    
    private var dailyData: [DailyData] {
        // Get all days data first
        let allDaysData = markerViewModel.getDailyMarkerData(
            dayRange: 1...7,
            for: timeframe,
            salesmanName: selectedSalesman,
            teamNumber: selectedTeam
        )
        
        // Always show Monday to Sunday (ordered)
        let orderedDays = [2, 3, 4, 5, 6, 7, 1] // Mon, Tue, Wed, Thu, Fri, Sat, Sun
        
        return orderedDays.compactMap { dayNumber in
            allDaysData.first { $0.weekday == dayNumber }
        }
    }
    
    private var maxCount: Int {
        dailyData.map(\.count).max() ?? 1
    }
    
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    private var teamMenu: some View {
        Menu {
            Button("All Teams") {
                selectedTeam = nil
            }
            
            ForEach(markerViewModel.getTeamNumbers(), id: \.self) { team in
                Button("Team \(team)") {
                    selectedTeam = team
                }
            }
        } label: {
            menuLabel(text: selectedTeam == nil ? "All Teams" : "Team \(selectedTeam!)")
        }
    }
    
    private var salesmanMenu: some View {
        Menu {
            Button("All Salesmen") {
                selectedSalesman = nil
            }
            
            ForEach(markerViewModel.getSalesmen(for: selectedTeam), id: \.self) { salesman in
                Button(salesman) {
                    selectedSalesman = salesman
                }
            }
        } label: {
            menuLabel(text: selectedSalesman ?? "All Salesmen")
        }
    }
    
    private func menuLabel(text: String) -> some View {
        HStack {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        )
    }
    
    private var dailyFiltersView: some View {
        VStack(spacing: 16) {
            // Team and salesman filters
            HStack(spacing: 16) {
                // Team Filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("Team")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    teamMenu
                }
                
                // Salesman Filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("Salesman")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    salesmanMenu
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with filter toggle
            HStack {
                VStack(alignment: .leading) {
                    Text("Daily Activity")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Monday - Sunday")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showFilters.toggle() 
                    }
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(showFilters ? .white : .indigo)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(showFilters ? Color.indigo : Color.clear)
                        )
                }
            }
            
            // Filter controls (shown when toggled)  
            if showFilters {
                dailyFiltersView
            }
            
            // Chart visualization
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 12) {
                    // Add leading spacer for centering
                    Spacer()
                    
                    ForEach(dailyData) { data in
                        VStack(spacing: 6) {
                            // Bar with count label
                            VStack {
                                if data.count > 0 {
                                    Text("\(data.count)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.indigo)
                                }
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(data.count > 0 ? Color.indigo.opacity(0.8) : Color.gray.opacity(0.3))
                                    .frame(
                                        width: 35,
                                        height: max(4, CGFloat(data.count) / CGFloat(maxCount) * 100)
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: data.count)
                            }
                            
                            // Day label
                            Text(data.label)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Add trailing spacer for centering
                    Spacer()
                }
                .padding(.horizontal)
            }
            .frame(height: 140)
            
            // Summary stats
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Markers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(dailyData.reduce(0) { $0 + $1.count })")
                        .font(.headline)
                        .foregroundColor(.indigo)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Peak Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let peak = dailyData.max(by: { $0.count < $1.count }) {
                        Text(peak.label)
                            .font(.headline)
                            .foregroundColor(.indigo)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.indigo.opacity(0.2), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Individual Chart Components
struct SimpleBarChart: View {
    let title: String
    let data: [ChartDataPoint]
    let color: Color
    
    private var maxValue: Double {
        data.map(\.value).max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(data, id: \.label) { point in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(color.opacity(0.8))
                            .frame(
                                width: 20,
                                height: max(4, point.value / maxValue * 100)
                            )
                        
                        Text(point.label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .frame(height: 120)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct SimpleLineChart: View {
    let title: String
    let data: [ChartDataPoint]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            Text("Line chart visualization")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct ChartDataPoint {
    let label: String
    let value: Double
}

// MARK: - Supporting Views
struct StatusDistributionView: View {
    let markers: [Marker]
    
    private var statusData: [StatusData] {
        let grouped = Dictionary(grouping: markers, by: \.status)
        
        return MarkerStatus.allCases.map { status in
            StatusData(
                status: status.displayName,
                count: grouped[status]?.count ?? 0,
                color: colorForStatus(status)
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status Distribution")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(statusData) { data in
                HStack {
                    Circle()
                        .fill(data.color)
                        .frame(width: 12, height: 12)
                    
                    Text(data.status)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(data.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(data.color)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func colorForStatus(_ status: MarkerStatus) -> Color {
        status.color
    }
}

struct StatusData: Identifiable {
    let id = UUID()
    let status: String
    let count: Int
    let color: Color
}

// MARK: - Team Views
struct TeamLeaderboardView: View {
    let timeframe: StatisticsTimeframe
    let onTeamTap: (Int) -> Void
    @ObservedObject var markerViewModel: MarkerViewModel
    
    private var teamStats: [TeamStats] {
        let teams = markerViewModel.getTeamNumbers()
        
        return teams.map { teamNumber in
            let markers = markerViewModel.getMarkers(for: timeframe, teamNumber: teamNumber)
            let soldCount = markers.filter { $0.status == .sold }.count
            let totalCount = markers.count
            
            return TeamStats(
                teamNumber: teamNumber,
                soldCount: soldCount,
                totalDoors: totalCount,
                conversionRate: totalCount > 0 ? Double(soldCount) / Double(totalCount) * 100 : 0
            )
        }
        .sorted { $0.conversionRate > $1.conversionRate }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(teamStats.enumerated()), id: \.element.teamNumber) { index, stats in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                    onTeamTap(stats.teamNumber)
                    }
                }) {
                    HStack(spacing: 16) {
                        // Rank badge
                        ZStack {
                            Circle()
                                .fill(rankColor(for: index))
                                .frame(width: 32, height: 32)
                            
                        Text("#\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                        Text("Team \(stats.teamNumber)")
                            .font(.headline)
                                .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            
                            Text("\(stats.totalDoors) doors knocked")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(stats.soldCount) Sales")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                            
                            Text(String(format: "%.1f%% conv.", stats.conversionRate))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0)
            }
        }
        .padding(.horizontal)
    }
    
    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return Color(red: 0.8, green: 0.6, blue: 0.0)  // Darker gold for 1st place
        case 1: return .gray    // Silver for 2nd place  
        case 2: return .orange  // Bronze for 3rd place
        default: return .blue   // Blue for others
        }
    }
}

struct TeamStats {
    let teamNumber: Int
    let soldCount: Int
    let totalDoors: Int
    let conversionRate: Double
}

struct TeamDetailView: View {
    let teamNumber: Int?
    let timeframe: StatisticsTimeframe
    @ObservedObject var markerViewModel: MarkerViewModel
    @State private var selectedTimeframe: StatisticsTimeframe = .weekly
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let teamNumber = teamNumber {
                        // 🧠 Debug: Log team data loading
                        let _ = print("🏢 TeamDetailView: Loading data for Team \(teamNumber)")
                        let _ = print("🏢 TeamDetailView: Selected timeframe: \(selectedTimeframe)")
                        
                        // Time Period Selector at the top
                        TimeframeSelectorView(selectedTimeframe: $selectedTimeframe)
                        
                        // 🧠 Debug: Show current state in UI
                        let teamMarkers = markerViewModel.getMarkers(for: selectedTimeframe, teamNumber: teamNumber)
                        VStack(spacing: 8) {
                            Text("DEBUG: Team \(teamNumber) - \(selectedTimeframe)")
                                .font(.caption)
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            
                            Text("Markers found: \(teamMarkers.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // Team-specific stats - Using exact same design as home page
                        LargeActivitySummaryView(
                            markers: teamMarkers,
                            timeframe: selectedTimeframe
                        )
                        
                        // Performance Metrics Cards (affected by timeframe)
                        EnhancedPerformanceMetricsView(
                            markers: teamMarkers,
                            timeframe: selectedTimeframe
                        )
                        
                        // Visual Divider
                        Divider()
                            .padding(.horizontal)
                        
                        // Per-salesman breakdown (uses original timeframe, not affected by selector)
                        SalesmanBreakdownView(teamNumber: teamNumber, timeframe: timeframe, markerViewModel: markerViewModel)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .navigationTitle(teamNumber != nil ? "Team \(teamNumber!)" : "Team Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Dismiss the sheet
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.3), value: false)
                }
            }
        }
    }
}

struct SalesmanBreakdownView: View {
    let teamNumber: Int
    let timeframe: StatisticsTimeframe
    @ObservedObject var markerViewModel: MarkerViewModel
    @State private var showingSalesmanDetail: String?
    
    private var salesmanStats: [SalesmanStats] {
        let salesmen = markerViewModel.getSalesmen(for: teamNumber)
        
        return salesmen.map { salesman in
            let markers = markerViewModel.getMarkers(for: timeframe, salesmanName: salesman, teamNumber: teamNumber)
            let soldCount = markers.filter { $0.status == .sold }.count
            let totalCount = markers.count
            
            return SalesmanStats(
                name: salesman,
                soldCount: soldCount,
                totalDoors: totalCount,
                conversionRate: totalCount > 0 ? Double(soldCount) / Double(totalCount) * 100 : 0
            )
        }
        .sorted { $0.conversionRate > $1.conversionRate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Salesman Performance")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
            ForEach(Array(salesmanStats.enumerated()), id: \.element.name) { index, stats in
                    Button(action: {
                        // Show detailed view for this salesman
                        showingSalesmanDetail = stats.name
                    }) {
                        HStack(spacing: 16) {
                            // Rank badge
                            ZStack {
                                Circle()
                                    .fill(salesmanRankColor(for: index))
                                    .frame(width: 28, height: 28)
                                
                    Text("#\(index + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                    Text(stats.name)
                        .font(.headline)
                                    .fontWeight(.semibold)
                        .foregroundColor(.primary)
                                
                                Text("\(stats.totalDoors) doors")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                    
                    Spacer()
                    
                                                    VStack(alignment: .trailing, spacing: 2) {
                                Text("\(stats.soldCount)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.blue)
                                
                                Text(String(format: "%.1f%%", stats.conversionRate))
                            .font(.caption)
                                    .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12, weight: .medium))
                }
                        .padding(12)
                .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray5), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: .constant(showingSalesmanDetail != nil)) {
            if let salesmanName = showingSalesmanDetail {
                SalesmanDetailView(
                    salesmanName: salesmanName,
                    teamNumber: teamNumber,
                    timeframe: timeframe,
                    markerViewModel: markerViewModel,
                    onDismiss: {
                        showingSalesmanDetail = nil
                    }
                )
            }
        }
    }
    
    private func salesmanRankColor(for index: Int) -> Color {
        switch index {
        case 0: return Color(red: 0.8, green: 0.6, blue: 0.0)  // Gold for 1st place
        case 1: return .gray    // Silver for 2nd place  
        case 2: return Color(red: 0.8, green: 0.5, blue: 0.2)  // Bronze for 3rd place
        default: return .gray   // Gray for others
        }
    }
}

struct SalesmanStats {
    let name: String
    let soldCount: Int
    let totalDoors: Int
    let conversionRate: Double
}

// MARK: - Salesman Detail View
struct SalesmanDetailView: View {
    let salesmanName: String
    let teamNumber: Int
    let timeframe: StatisticsTimeframe
    @ObservedObject var markerViewModel: MarkerViewModel
    let onDismiss: () -> Void
    @State private var selectedTimeframe: StatisticsTimeframe = .weekly
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 🧠 Debug: Log salesman data loading
                    let _ = print("👤 SalesmanDetailView: Loading data for '\(salesmanName)' in Team \(teamNumber)")
                    let _ = print("👤 SalesmanDetailView: Selected timeframe: \(selectedTimeframe)")
                    
                    // Time Period Selector at the top
                    TimeframeSelectorView(selectedTimeframe: $selectedTimeframe)
                    
                    // 🧠 Debug: Show current state in UI
                    let salesmanMarkers = markerViewModel.getMarkers(for: selectedTimeframe, salesmanName: salesmanName, teamNumber: teamNumber)
                    VStack(spacing: 8) {
                        Text("DEBUG: \(salesmanName) (Team \(teamNumber)) - \(selectedTimeframe)")
                            .font(.caption)
                            .padding(8)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text("Markers found: \(salesmanMarkers.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Salesman-specific stats - Using exact same design as team page
                    LargeActivitySummaryView(
                        markers: salesmanMarkers,
                        timeframe: selectedTimeframe
                    )
                    
                    // Performance Metrics Cards (affected by timeframe)
                    EnhancedPerformanceMetricsView(
                        markers: salesmanMarkers,
                        timeframe: selectedTimeframe
                    )
                    
                    // Visual Divider
                    Divider()
                        .padding(.horizontal)
                    
                    // Historical Charts for Salesman
                    SalesmanHistoricalChartsView(
                        salesmanName: salesmanName,
                        teamNumber: teamNumber,
                        timeframe: timeframe,
                        markerViewModel: markerViewModel
                    )
                    
                    // Individual performance summary
                    SalesmanPerformanceSummaryView(
                        salesmanName: salesmanName,
                        teamNumber: teamNumber,
                        timeframe: timeframe,
                        markerViewModel: markerViewModel
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .navigationTitle(salesmanName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onDismiss) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Salesman Historical Charts
struct SalesmanHistoricalChartsView: View {
    let salesmanName: String
    let teamNumber: Int
    let timeframe: StatisticsTimeframe
    @ObservedObject var markerViewModel: MarkerViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Hourly Activity Chart for Salesman
            SalesmanHourlyChart(
                salesmanName: salesmanName,
                teamNumber: teamNumber,
                timeframe: timeframe,
                markerViewModel: markerViewModel
            )
            
            // Daily Activity Chart for Salesman
            SalesmanDailyChart(
                salesmanName: salesmanName,
                teamNumber: teamNumber,
                timeframe: timeframe,
                markerViewModel: markerViewModel
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Salesman Hourly Chart
struct SalesmanHourlyChart: View {
    let salesmanName: String
    let teamNumber: Int
    let timeframe: StatisticsTimeframe
    @ObservedObject var markerViewModel: MarkerViewModel
    
    private var hourlyData: [HourlyData] {
        markerViewModel.getHourlyMarkerData(
            hourRange: 0...23,
            for: timeframe,
            salesmanName: salesmanName,
            teamNumber: teamNumber
        )
    }
    
    private var maxCount: Int {
        hourlyData.map(\.count).max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Hourly Activity Pattern")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(timeframe.rawValue) activity by hour of day")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Chart visualization
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(hourlyData) { data in
                        VStack(spacing: 4) {
                            // Bar with count label
                            VStack {
                                if data.count > 0 {
                                    Text("\(data.count)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.purple)
                                }
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(data.count > 0 ? Color.purple.opacity(0.8) : Color.gray.opacity(0.3))
                                    .frame(
                                        width: 24,
                                        height: max(4, CGFloat(data.count) / CGFloat(maxCount) * 100)
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: data.count)
                            }
                            
                            // Hour label
                            Text(data.label)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Summary stats
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Doors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(hourlyData.reduce(0) { $0 + $1.count })")
                        .font(.headline)
                        .foregroundColor(.purple)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Peak Hour")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let peak = hourlyData.max(by: { $0.count < $1.count }), peak.count > 0 {
                        Text(peak.label)
                            .font(.headline)
                            .foregroundColor(.purple)
                    } else {
                        Text("No data")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Salesman Daily Chart
struct SalesmanDailyChart: View {
    let salesmanName: String
    let teamNumber: Int
    let timeframe: StatisticsTimeframe
    @ObservedObject var markerViewModel: MarkerViewModel
    
    private var dailyData: [DailyData] {
        // Get all days data first
        let allDaysData = markerViewModel.getDailyMarkerData(
            dayRange: 1...7,
            for: timeframe,
            salesmanName: salesmanName,
            teamNumber: teamNumber
        )
        
        // Always show Monday to Sunday (ordered)
        let orderedDays = [2, 3, 4, 5, 6, 7, 1] // Mon, Tue, Wed, Thu, Fri, Sat, Sun
        
        return orderedDays.compactMap { dayNumber in
            allDaysData.first { $0.weekday == dayNumber }
        }
    }
    
    private var maxCount: Int {
        dailyData.map(\.count).max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Activity Pattern")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(timeframe.rawValue) activity by day of week")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Chart visualization
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(dailyData) { data in
                    VStack(spacing: 6) {
                        // Bar with count label
                        VStack {
                            if data.count > 0 {
                                Text("\(data.count)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(data.count > 0 ? Color.orange.opacity(0.8) : Color.gray.opacity(0.3))
                                .frame(
                                    width: 32,
                                    height: max(4, CGFloat(data.count) / CGFloat(maxCount) * 100)
                                )
                                .animation(.easeInOut(duration: 0.3), value: data.count)
                        }
                        
                        // Day label
                        Text(data.label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 120)
            
            // Summary stats
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Doors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(dailyData.reduce(0) { $0 + $1.count })")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Peak Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let peak = dailyData.max(by: { $0.count < $1.count }), peak.count > 0 {
                        Text(peak.label)
                            .font(.headline)
                            .foregroundColor(.orange)
                    } else {
                        Text("No data")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Salesman Performance Summary
struct SalesmanPerformanceSummaryView: View {
    let salesmanName: String
    let teamNumber: Int
    let timeframe: StatisticsTimeframe
    @ObservedObject var markerViewModel: MarkerViewModel
    
    private var salesmanMarkers: [Marker] {
        markerViewModel.getMarkers(for: timeframe, salesmanName: salesmanName, teamNumber: teamNumber)
    }
    
    private var hourlyBreakdown: [HourlyData] {
        markerViewModel.getHourlyMarkerData(for: timeframe, salesmanName: salesmanName, teamNumber: teamNumber)
    }
    
    private var dailyBreakdown: [DailyData] {
        markerViewModel.getDailyMarkerData(for: timeframe, salesmanName: salesmanName, teamNumber: teamNumber)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Performance Details")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Activity by hour summary
            VStack(alignment: .leading, spacing: 12) {
                Text("Most Active Hours")
                    .font(.headline)
                    .padding(.horizontal)
                
                let topHours = hourlyBreakdown.filter { $0.count > 0 }.sorted { $0.count > $1.count }.prefix(3)
                
                ForEach(Array(topHours.enumerated()), id: \.element.id) { index, hourData in
                    HStack {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        Text(hourData.label)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(hourData.count) doors")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
            
            // Activity by day summary
            VStack(alignment: .leading, spacing: 12) {
                Text("Most Active Days")
                    .font(.headline)
                    .padding(.horizontal)
                
                let topDays = dailyBreakdown.filter { $0.count > 0 }.sorted { $0.count > $1.count }.prefix(3)
                
                ForEach(Array(topDays.enumerated()), id: \.element.id) { index, dayData in
                    HStack {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        Text(dayData.label)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(dayData.count) doors")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Timeframe Selector View
struct TimeframeSelectorView: View {
    @Binding var selectedTimeframe: StatisticsTimeframe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Period")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(StatisticsTimeframe.allCases, id: \.self) { timeframe in
                        Button(action: {
                            selectedTimeframe = timeframe
                        }) {
                            Text(timeframe.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedTimeframe == timeframe ? Color.blue : Color(.systemGray5))
                                )
                                .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Enhanced Performance Metrics View
struct EnhancedPerformanceMetricsView: View {
    let markers: [Marker]
    let timeframe: StatisticsTimeframe
    
    private var soldCount: Int {
        markers.filter { $0.status == .sold }.count
    }
    
    private var notInterestedCount: Int {
        markers.filter { $0.status == .notInterested }.count
    }
    
    private var totalDoors: Int {
        markers.count
    }
    
    private var primaryConversionRate: Double {
        // Primary Conversion Rate = Sold / (Sold + Not Interested)
        let primaryTotal = soldCount + notInterestedCount
        return primaryTotal > 0 ? Double(soldCount) / Double(primaryTotal) * 100 : 0
    }
    
    private var outreachRate: Double {
        // Outreach Ratio = Sales / Total Doors
        return totalDoors > 0 ? Double(soldCount) / Double(totalDoors) * 100 : 0
    }
    
    private var primaryConversionCard: some View {
        EnhancedMetricCard(
            title: "Primary Conversion",
            subtitle: "Sales / Total Conversations",
                value: String(format: "%.1f%%", primaryConversionRate),
            description: "",
                color: .purple,
                icon: "percent"
            )
    }
            
    private var outreachRatioCard: some View {
        EnhancedMetricCard(
                title: "Outreach Ratio",
            subtitle: "Sales / Total Doors",
                value: String(format: "%.1f%%", outreachRate),
            description: "",
                color: .indigo,
                icon: "target"
            )
        }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Performance Metrics")
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                outreachRatioCard
                primaryConversionCard
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Enhanced Metric Card Component
struct EnhancedMetricCard: View {
    let title: String
    let subtitle: String
    let value: String
    let description: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 8)
                
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            if !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(minHeight: 80) // Reduced height since no description
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1.5)
                )
        )
        .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Statistics Connection Card
struct StatisticsConnectionCard: View {
    @ObservedObject var markerVM: MarkerViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(markerVM.isOffline ? Color.red : Color.green)
                    .frame(width: 40, height: 40)
                
                Image(systemName: markerVM.isOffline ? "wifi.slash" : "wifi")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(markerVM.isOffline ? "Offline Mode" : "Connected - Real-time Active")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                if markerVM.isOffline {
                    Text("Data will sync when online")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(markerVM.isOffline ? Color.red.opacity(0.08) : Color.green.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(markerVM.isOffline ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    StatisticsView(markerViewModel: MarkerViewModel())
} 