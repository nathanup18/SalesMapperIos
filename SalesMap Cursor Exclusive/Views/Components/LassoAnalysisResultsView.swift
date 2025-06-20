import SwiftUI

struct LassoAnalysisResultsView: View {
    let analysisResult: LassoAnalysisResult
    let onDismiss: () -> Void
    let onClearSelection: () -> Void
    
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with summary
                headerSection
                
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    typeBreakdownView
                        .tag(0)
                    
                    userTimeBreakdownView
                        .tag(1)
                    
                    markerListView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Lasso Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Draw Again") {
                        print("🎯 USER: Draw again selected")
                        onClearSelection()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        print("🎯 USER: Analysis dismissed - exiting lasso mode")
                        onDismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lasso")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                                    Text(analysisResult.totalCount > 0 ? "\(analysisResult.totalCount) Markers Selected" : "No Markers Selected")
                    .font(.headline)
                    .foregroundColor(analysisResult.totalCount > 0 ? .primary : .orange)
                    
                    Text(analysisResult.selectionArea)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Quick stats
            HStack(spacing: 20) {
                StatPill(
                    label: "Sold",
                    count: analysisResult.typeBreakdown.sold,
                    color: .green
                )
                
                StatPill(
                    label: "Not Interested",
                    count: analysisResult.typeBreakdown.notInterested,
                    color: .red
                )
                
                StatPill(
                    label: "Not Home",
                    count: analysisResult.typeBreakdown.notHome,
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "Types", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabButton(title: "Users & Time", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            TabButton(title: "Markers", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .background(Color(.systemGray5))
    }
    
    // MARK: - Type Breakdown View
    
    private var typeBreakdownView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Pie chart representation
                pieChartView
                
                // Detailed breakdown
                typeDetailsView
            }
            .padding()
        }
    }
    
    private var pieChartView: some View {
        VStack(spacing: 16) {
            Text("Marker Type Distribution")
                .font(.headline)
            
            // Simple visual representation using progress bars
            VStack(spacing: 12) {
                ForEach(analysisResult.typeBreakdown.breakdown, id: \.0) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle()
                                .fill(item.2)
                                .frame(width: 12, height: 12)
                            
                            Text(item.0)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(item.1)")
                                .font(.headline)
                                .foregroundColor(item.2)
                            
                            Text("(\(percentage(item.1))%)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(item.2)
                                    .frame(width: geometry.size.width * CGFloat(percentage(item.1)) / 100.0, height: 8)
                                    .cornerRadius(4)
                                    .animation(.easeInOut(duration: 0.5), value: item.1)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var typeDetailsView: some View {
        VStack(spacing: 12) {
            Text("Detailed Breakdown")
                .font(.headline)
            
            ForEach(analysisResult.typeBreakdown.breakdown, id: \.0) { item in
                HStack {
                    Circle()
                        .fill(item.2)
                        .frame(width: 12, height: 12)
                    
                    Text(item.0)
                        .font(.body)
                    
                    Spacer()
                    
                    Text("\(item.1)")
                        .font(.headline)
                        .foregroundColor(item.2)
                    
                    Text("(\(percentage(item.1))%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 1)
            }
        }
    }
    
    // MARK: - User & Time Breakdown View
    
    private var userTimeBreakdownView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top users
                topUsersSection
                
                // Team breakdown
                teamBreakdownSection
                
                // Recent activity
                recentActivitySection
            }
            .padding()
        }
    }
    
    private var topUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Contributors")
                .font(.headline)
            
            ForEach(Array(analysisResult.userTimeBreakdown.topUsers.prefix(5).enumerated()), id: \.offset) { index, user in
                HStack {
                    Text("\(index + 1).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20, alignment: .leading)
                    
                    Text(user.0)
                        .font(.body)
                    
                    Spacer()
                    
                    Text("\(user.1)")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private var teamBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Team Distribution")
                .font(.headline)
            
            ForEach(Array(analysisResult.userTimeBreakdown.teamCounts.sorted(by: { $0.key < $1.key })), id: \.key) { team, count in
                HStack {
                    Text("Team \(team)")
                        .font(.body)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity (Last 7 Days)")
                .font(.headline)
            
            ForEach(analysisResult.userTimeBreakdown.recentActivity, id: \.0) { day, count in
                HStack {
                    Text(formatDate(day))
                        .font(.body)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.headline)
                        .foregroundColor(.purple)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Marker List View
    
    private var markerListView: some View {
        List(analysisResult.selectedMarkers) { marker in
            MarkerRowView(marker: marker)
        }
    }
    
    // MARK: - Helper Functions
    
    private func percentage(_ count: Int) -> Int {
        guard analysisResult.totalCount > 0 else { return 0 }
        return Int(round(Double(count) / Double(analysisResult.totalCount) * 100))
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
        
        return dateString
    }
}

// MARK: - Supporting Views

struct StatPill: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .blue : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .background(isSelected ? Color(.systemBackground) : Color.clear)
    }
}

struct MarkerRowView: View {
    let marker: Marker
    
    var body: some View {
        HStack {
            Circle()
                .fill(marker.statusColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(marker.displayStatus)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(marker.salesman_name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatTimestamp(marker.created_at))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Team \(marker.team_number)")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                if !marker.notes.isEmpty {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 