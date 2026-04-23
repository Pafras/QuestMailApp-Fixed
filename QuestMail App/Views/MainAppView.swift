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
    
    var icon: String {
        switch self {
        case .onSchedule: return "calendar.badge.clock"
        case .desires: return "heart.fill"
        case .activityPlanning: return "list.clipboard.fill"
        }
    }
    
    var tintColor: Color {
        switch self {
        case .onSchedule: return .blue
        case .desires: return .orange
        case .activityPlanning: return .green
        }
    }
    
    var categoryTitle: String {
        switch self {
        case .onSchedule: return "Scheduled Quests"
        case .desires: return "Desires & Wishes"
        case .activityPlanning: return "Activity Planning"
        }
    }
    
    var categoryDescription: String {
        switch self {
        case .onSchedule: return "Keep track of your upcoming quests, including scheduled events and meetups."
        case .desires: return "Browse and upvote activities you'd love to try, bundled by popularity."
        case .activityPlanning: return "Organize and plan new activities with your group, from idea to execution."
        }
    }
}

// MARK: - MainAppView
struct MainAppView: View {
    
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
                            quests: SampleData.scheduledQuests,
                            selectedQuest: $selectedQuest,
                            rsvpedQuestIDs: $rsvpedQuestIDs
                        )
                    case .desires:
                        DesiresView(
                            activities: $desireActivities,
                            selectedActivity: $selectedActivity,
                            onComposeQuest: { desireID in
                                composeMode = .compose
                                composingDesireID = desireID
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
                            activityPlans.append(plan)
                            // Remove desire from list when submitted from Desires tab
                            if let desireID = composingDesireID {
                                desireActivities.removeAll { $0.id == desireID }
                                composingDesireID = nil
                            }
                            selectedTab = .activityPlanning
                        }
                    }
                )
            }
            .onChange(of: selectedPlan) { _, plan in
                if let plan {
                    composeMode = .editPlan
                    composeInitialTitle = plan.title
                    composeInitialActivity = plan.activity
                    selectedPlan = nil
                    showComposeCard = true
                }
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
}

// MARK: - Preview
#Preview {
    MainAppView()
}
