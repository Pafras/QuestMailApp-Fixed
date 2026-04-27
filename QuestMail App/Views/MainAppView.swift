//
//  MainAppView.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 19/04/26.
//

import SwiftUI

// MARK: - QuestTab Enum
enum QuestTab: String, CaseIterable {
    case onSchedule = "On Schedule"
    case desires = "Desires"
    case activityPlanning = "Activity Planning"
    case history = "History"
    
    var icon: String {
        switch self {
        case .onSchedule: return "calendar.badge.clock"
        case .desires: return "heart.fill"
        case .activityPlanning: return "list.clipboard.fill"
        case .history: return "clock.arrow.circlepath"
        }
    }
    
    var tintColor: Color {
        switch self {
        case .onSchedule: return .blue
        case .desires: return .orange
        case .activityPlanning: return .green
        case .history: return .purple
        }
    }
    
    var categoryTitle: String {
        switch self {
        case .onSchedule: return "Scheduled Quests"
        case .desires: return "Desires & Wishes"
        case .activityPlanning: return "Activity Planning"
        case .history: return "My Quest History"
        }
    }
    
    var categoryDescription: String {
        switch self {
        case .onSchedule: return "Keep track of your upcoming quests, including scheduled events and meetups."
        case .desires: return "Browse and upvote activities you'd love to try, bundled by popularity."
        case .activityPlanning: return "Organize and plan new activities with your group, from idea to execution."
        case .history: return "Quests you've RSVPed to, upcoming and completed."
        }
    }
}

// MARK: - MainAppView
struct MainAppView: View {
    
    // stores the wantCount from the desire that triggered compose
    // passed into the ActivityPlan as interestedCount when submitted
    @State private var composingDesireWantCount: Int = 0
    
    // MainAppView owns the array so it can mutate individual items
    @State private var scheduledQuests: [ScheduledQuest] = SampleData.scheduledQuests
    
    // MARK: - Properties
    @State private var selectedTab: QuestTab = .onSchedule
    @State private var showCategoryBanner: Bool = true
    @Namespace private var tabAnimation
    
    // MARK: Navigation State (for detail screens)
    @State private var selectedQuest: ScheduledQuest?
    @State private var selectedActivity: DesireActivity?
    @State private var selectedPlan: ActivityPlan?
    @State private var showComposeCard = false
    @State private var composeMode: ComposeMode = .compose
    @State private var composeInitialTitle: String = ""
    @State private var composeInitialActivity: String = ""
    
    // MARK: Data State
    @State private var desireActivities: [DesireActivity] = SampleData.desireActivities
    @State private var activityPlans: [ActivityPlan] = SampleData.activityPlans
    @State private var composingDesireID: UUID?
    @State private var editingPlanID: UUID?
    
    // MARK: RSVP State
    @State private var rsvpedQuestIDs: Set<UUID> = []
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Navigation Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quest Board")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("The Bridge Tavern")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                // MARK: Tab Bar
                mailTabBar
                    .padding(.bottom, 4)
                
                // MARK: Category Description Banner
                if showCategoryBanner {
                    categoryBanner
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                }
                
                // MARK: Tab Content
                Group {
                    switch selectedTab {
                    case .onSchedule:
                        OnScheduleView(
                            quests: scheduledQuests,
                            selectedQuest: $selectedQuest,
                            rsvpedQuestIDs: $rsvpedQuestIDs,
                            // wires the same handleRSVPChange function used by the detail view
                            // so both swipe and detail view update the same array
                            onRSVPChange: { questID, isJoining in
                                handleRSVPChange(questID: questID, isJoining: isJoining)
                            }
                        )
                    case .desires:
                        DesiresView(
                            activities: $desireActivities,
                            selectedActivity: $selectedActivity,
                            onComposeQuest: { desireID in
                                composeMode = .compose
                                composingDesireID = desireID
                                // find the desire by id and store its wantCount
                                // so it can become interestedCount in the ActivityPlan
                                if let desireItem = desireActivities.first(where: { eachDesire in eachDesire.id == desireID }) {
                                    composingDesireWantCount = desireItem.wantCount
                                }
                                composeInitialTitle = ""
                                composeInitialActivity = ""
                                showComposeCard = true
                            }
                        )
                    case .activityPlanning:
                        ActivityPlanningView(
                            plans: activityPlans,
                            selectedPlan: $selectedPlan
                        )
                    case .history:
                        // passes the full quest array + the set of RSVPed IDs
                        // HistoryView will filter internally to find the ones the user joined
                        HistoryView(
                            questsData: scheduledQuests,         // source: MainAppView's @State array
                            rsvpedQuestIDs: rsvpedQuestIDs       // source: MainAppView's @State set — NOT a binding, read-only here
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
            }
            .navigationDestination(isPresented: $showComposeCard) {
                ComposeActivityCard(
                    mode: composeMode,
                    initialTitle: composeInitialTitle,
                    initialActivity: composeInitialActivity,
                    onSubmit: { plan in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                            if composeMode == .compose {
                                var updatedPlanItem = plan           // make a mutable copy of the plan
                                updatedPlanItem.interestedCount = composingDesireWantCount  // inject the desire's wantCount
                                activityPlans.append(updatedPlanItem)   // append the updated copy, not the original
                                if let desireID = composingDesireID {
                                    desireActivities.removeAll { $0.id == desireID }
                                    composingDesireID = nil
                                }
                                selectedTab = .activityPlanning
                            } else {
                                // From Activity Planning: remove plan, create ScheduledQuest, go to On Schedule
                                if let planID = editingPlanID {
                                    activityPlans.removeAll { $0.id == planID }
                                    editingPlanID = nil
                                }
                                let newQuest = createScheduledQuest(from: plan)
                                scheduledQuests.append(newQuest)
                                selectedTab = .onSchedule
                            }
                        }
                    }
                )
            }
            .onChange(of: selectedPlan) { _, plan in
                if let plan {
                    composeMode = .editPlan
                    editingPlanID = plan.id
                    composeInitialTitle = plan.title
                    composeInitialActivity = plan.activity
                    selectedPlan = nil
                    showComposeCard = true
                }
            }
            // questItem = the ScheduledQuest that was tapped in OnScheduleView
            // selected via selectedQuest @State in MainAppView, set inside SwipeableQuestRow's onTapGesture
            .navigationDestination(item: $selectedQuest) { questItem in
                ScheduledQuestDetailView(
                    onRSVPChange: { questID, isJoining in
                        handleRSVPChange(questID: questID, isJoining: isJoining)
                    },
                    questData: questItem,
                    rsvpedQuestIDs: $rsvpedQuestIDs
                )
            }
        }
    }
    
    // MARK: - Mail-style Tab Bar
    private var mailTabBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(QuestTab.allCases, id: \.self) { tab in
                        let isSelected = selectedTab == tab
                        
                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                                selectedTab = tab
                                showCategoryBanner = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                if isSelected {
                                    Text(tab.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                        .transition(.asymmetric(
                                            insertion: .push(from: .leading).combined(with: .opacity),
                                            removal: .push(from: .trailing).combined(with: .opacity)
                                        ))
                                }
                            }
                            .foregroundStyle(isSelected ? .white : .secondary)
                            .padding(.horizontal, isSelected ? 16 : 0)
                            .padding(.vertical, 10)
                            .frame(width: isSelected ? nil : 42, height: 42)
                            .background {
                                if isSelected {
                                    Capsule()
                                        .fill(tab.tintColor)
                                        .matchedGeometryEffect(id: "tabBg", in: tabAnimation)
                                } else {
                                    Circle()
                                        .fill(Color(.systemGray5))
                                        .matchedGeometryEffect(id: "tab_\(tab.rawValue)", in: tabAnimation)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .id(tab)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            .onChange(of: selectedTab) { _, newTab in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    proxy.scrollTo(newTab, anchor: .center)
                }
            }
        }
    }
    
    // MARK: - Category Description Banner
    private var categoryBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedTab.categoryTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(selectedTab.tintColor)
                
                Text(selectedTab.categoryDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showCategoryBanner = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(selectedTab.tintColor.opacity(0.7))
                    .padding(6)
                    .background(
                        Circle()
                            .fill(selectedTab.tintColor.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(selectedTab.tintColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(selectedTab.tintColor.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
    }
    
    // MARK: - Create ScheduledQuest from ActivityPlan
    private func createScheduledQuest(from plan: ActivityPlan) -> ScheduledQuest {
        // Combine plan.date (day) and plan.time (hour/minute) into a single Date
        let cal = Calendar.current
        let dayComponents = cal.dateComponents([.year, .month, .day], from: plan.date)
        let timeComponents = cal.dateComponents([.hour, .minute], from: plan.time)
        var combined = DateComponents()
        combined.year = dayComponents.year
        combined.month = dayComponents.month
        combined.day = dayComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        let scheduledDate = cal.date(from: combined) ?? plan.date
        
        return ScheduledQuest(
            title: plan.title,
            venue: plan.place.isEmpty ? "TBD" : plan.place,
            scheduledDate: scheduledDate,
            iconName: "star.fill",
            participantType: plan.participantType,
            maxParticipants: plan.maxParticipants,
            rsvpCount: 0,
            activityDetail: plan.activity,
            reward: plan.reward,
            organizer: plan.organizer
        )
    }
    
    // finds the quest by id in the @State array and increments or decrements rsvpCount
    // called FROM ScheduledQuestDetailView via the onRSVPChange closure
    private func handleRSVPChange(questID: UUID, isJoining: Bool) {
        guard let questIndex = scheduledQuests.firstIndex(where: { $0.id == questID }) else { return }
        if isJoining {
            scheduledQuests[questIndex].rsvpCount += 1
        } else {
            scheduledQuests[questIndex].rsvpCount -= 1
        }
    }
}

// MARK: - Preview
#Preview {
    MainAppView()
}
