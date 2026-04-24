//
//  DesiresView.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 19/04/26.
//

import SwiftUI

// MARK: - DesiresView
struct DesiresView: View {
    @Binding var activities: [DesireActivity]
    @Binding var selectedActivity: DesireActivity?
    var onComposeQuest: (UUID) -> Void
    
    // MARK: State
    @State private var votedIDs: Set<UUID> = []
    @State private var showAddDesire = false
    @State private var showAddSuccess = false
    @State private var animatingVoteID: UUID?
    @Namespace private var cardAnimation
    
    // MARK: Computed - sorted by votes
    private var sortedActivities: [DesireActivity] {
        activities.sorted { $0.wantCount > $1.wantCount }
    }
    
    private var featuredActivities: [DesireActivity] {
        Array(sortedActivities.prefix(2))
    }
    
    private var otherActivities: [DesireActivity] {
        Array(sortedActivities.dropFirst(2))
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    // MARK: Body
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: Vote Hint
                    HStack {
                        Image(systemName: "hand.tap")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("tap to vote")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    
                    // MARK: Featured Section
                    Text("Featured")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    ForEach(featuredActivities) { activity in
                        FeaturedDesireCard(
                            activity: activity,
                            hasVoted: votedIDs.contains(activity.id),
                            isAnimating: animatingVoteID == activity.id,
                            onVote: { toggleVote(for: activity.id) },
                            onCompose: { onComposeQuest(activity.id) }
                        )
                        .matchedGeometryEffect(id: activity.id, in: cardAnimation)
                        .id(activity.id)
                        .onTapGesture {
                            selectedActivity = activity
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: Others Section
                    Text("Others")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(otherActivities) { activity in
                            DesireCard(
                                activity: activity,
                                hasVoted: votedIDs.contains(activity.id),
                                isAnimating: animatingVoteID == activity.id,
                                onVote: { toggleVote(for: activity.id) }
                            )
                            .matchedGeometryEffect(id: activity.id, in: cardAnimation)
                            .id(activity.id)
                            .onTapGesture {
                                selectedActivity = activity
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer().frame(height: 80)
                }
                .padding(.top, 8)
                .animation(.spring(response: 0.45, dampingFraction: 0.75), value: sortedActivities.map(\.id))
            }
            
            // MARK: Floating Compose Button (Add Desire)
            Button {
                showAddDesire = true
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(
                        Circle()
                            .fill(Color.orange)
                            .shadow(color: .orange.opacity(0.4), radius: 8, y: 4)
                    )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            
            // MARK: Success Popup
            if showAddSuccess {
                addSuccessOverlay
            }
        }
        .sheet(isPresented: $showAddDesire) {
            AddDesireSheet(onAdd: { title in
                let newDesire = DesireActivity(
                    title: title,
                    subtitle: "",
                    wantCount: 1,
                    iconName: "triangle.fill",
                    iconColor: "cyan"
                )
                activities.append(newDesire)
                showAddDesire = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showAddSuccess = true
                }
            })
            .presentationDetents([.height(240)])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Toggle Vote
    private func toggleVote(for id: UUID) {
        // Start card bounce animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            animatingVoteID = id
        }
        
        // Update vote count after a tiny delay so animation is visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                if let index = activities.firstIndex(where: { $0.id == id }) {
                    if votedIDs.contains(id) {
                        votedIDs.remove(id)
                        activities[index].wantCount -= 1
                    } else {
                        votedIDs.insert(id)
                        activities[index].wantCount += 1
                    }
                }
            }
        }
        
        // Reset bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                animatingVoteID = nil
            }
        }
    }
    
    // MARK: - Success Overlay
    private var addSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showAddSuccess = false
                    }
                }
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.orange)
                    .symbolEffect(.bounce, value: showAddSuccess)
                
                Text("Desire Added!")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Your desire has been posted.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showAddSuccess = false
                    }
                } label: {
                    Text("OK")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange)
                        )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            )
            .padding(.horizontal, 40)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }
}

// MARK: - Featured Desire Card (Full Width, Compose Icon, Top 2 Desires)
struct FeaturedDesireCard: View {
    let activity: DesireActivity
    let hasVoted: Bool
    let isAnimating: Bool
    let onVote: () -> Void
    let onCompose: () -> Void
    
    // MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // MARK: Title
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if !activity.subtitle.isEmpty {
                        Text(activity.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // MARK: Compose Icon (Plan this desire)
                Button {
                    onCompose()
                } label: {
                    Image(systemName: "pencil")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.orange.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
            
            // MARK: Vote Row
            HStack(spacing: 6) {
                Button {
                    onVote()
                } label: {
                    Image(systemName: activity.iconName)
                        .font(.caption)
                        .foregroundStyle(iconColor)
                }
                .buttonStyle(.plain)
                
                Text("\(activity.wantCount) want this")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                
                if hasVoted {
                    Text("Voted")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isAnimating ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isAnimating)
    }
    
    // MARK: Icon Color
    private var iconColor: Color {
        switch activity.iconColor {
        case "orange": return .orange
        case "yellow": return .yellow
        case "cyan": return .cyan
        default: return .gray
        }
    }
}

// MARK: - DesireCard (Grid Card and Least Desire Vote)
struct DesireCard: View {
    let activity: DesireActivity
    let hasVoted: Bool
    let isAnimating: Bool
    let onVote: () -> Void
    
    // MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: Title
            Text(activity.title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // MARK: Subtitle
            if !activity.subtitle.isEmpty {
                Text(activity.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // MARK: Vote Row
            HStack(spacing: 6) {
                Button {
                    onVote()
                } label: {
                    Image(systemName: activity.iconName)
                        .font(.caption)
                        .foregroundStyle(iconColor)
                }
                .buttonStyle(.plain)
                
                Text("\(activity.wantCount) want this")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                
                if hasVoted {
                    Text("Voted")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isAnimating ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isAnimating)
    }
    
    // MARK: Icon Color
    private var iconColor: Color {
        switch activity.iconColor {
        case "orange": return .orange
        case "yellow": return .yellow
        case "cyan": return .cyan
        default: return .gray
        }
    }
}

// MARK: - Add Desire Sheet
struct AddDesireSheet: View {
    var onAdd: (String) -> Void
    @State private var desireTitle: String = ""
    @Environment(\.dismiss) private var dismiss
    
    private var isValid: Bool {
        !desireTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Desire")
                .font(.title3)
                .fontWeight(.bold)
            
            TextField("What activity do you wish for?", text: $desireTitle)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color(.systemGray4), lineWidth: 1)
                        )
                )
            
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color(.systemGray3), lineWidth: 1)
                                )
                        )
                }
                
                Button {
                    onAdd(desireTitle)
                } label: {
                    Text("Add Desire")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isValid ? Color.orange : Color(.systemGray4))
                        )
                }
                .disabled(!isValid)
                .animation(.easeInOut(duration: 0.2), value: isValid)
            }
        }
        .padding(20)
    }
}

// MARK: - Preview
#Preview {
    DesiresView(
        activities: .constant(SampleData.desireActivities),
        selectedActivity: .constant(nil),
        onComposeQuest: { _ in }
    )
}
