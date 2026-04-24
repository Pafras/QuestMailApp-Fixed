//
//  HistoryView.swift
//  QuestMail App
//
//  Created by Eduardo Richie Imanuell on 24/04/26.

import SwiftUI

struct HistoryView: View {

    // questsData: passed FROM MainAppView's scheduledQuests @State array
    // read-only — this view only displays, never mutates
    let questsData: [ScheduledQuest]

    // rsvpedQuestIDs: passed FROM MainAppView's rsvpedQuestIDs @State set
    // used to filter which quests the user actually joined
    // NOT a binding — this view doesn't need to change it
    let rsvpedQuestIDs: Set<UUID>

    // MARK: - Computed
    // filters questsData to only quests the user RSVPed to
    // source: questsData + rsvpedQuestIDs, both from MainAppView
    private var rsvpedQuests: [ScheduledQuest] {
        questsData.filter { questItem in rsvpedQuestIDs.contains(questItem.id) }
    }

    // upcoming = RSVPed quests where the date is in the future
    // source: rsvpedQuests filtered by scheduledDate vs today
    private var upcomingQuests: [ScheduledQuest] {
        rsvpedQuests
            .filter { questItem in
                questItem.scheduledDate >= Date()
            }
            .sorted { firstQuest, secondQuest in
                firstQuest.scheduledDate < secondQuest.scheduledDate
            }  // nearest first
    }

    // completed = RSVPed quests where the date has already passed
    // source: rsvpedQuests filtered by scheduledDate vs today
    private var completedQuests: [ScheduledQuest] {
        rsvpedQuests
            .filter { questItem in
                questItem.scheduledDate < Date()
            }
            .sorted { firstQuest, secondQuest in
                firstQuest.scheduledDate > secondQuest.scheduledDate
            }  // most recent first
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Upcoming Section
                Text("Upcoming")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                if upcomingQuests.isEmpty {
                    // shown when user hasn't RSVPed to any future quest
                    emptyState(message: "No upcoming quests. Go RSVP to something!")
                } else {
                    ForEach(upcomingQuests) { questItem in
                        // reuses QuestRow from OnScheduleView
                        // isRSVPed is always true here since its filtered alrd
                        QuestRow(quest: questItem, isRSVPed: true)
                        Divider().padding(.horizontal)
                    }
                }

                // MARK: Completed Section
                Text("Completed")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                if completedQuests.isEmpty {
                    // shown when no past quests have been RSVPed to
                    emptyState(message: "No completed quests yet.")
                } else {
                    ForEach(completedQuests) { questItem in
                        // same QuestRow reuse, completed ones shown slightly dimmed
                        QuestRow(quest: questItem, isRSVPed: true)
                            .opacity(0.5)  // visual hint that these are in the past
                        Divider().padding(.horizontal)
                    }
                }

                Spacer().frame(height: 40)
            }
        }
    }

    // MARK: - Empty State
    // reusable helper, shown when either upcoming or completed list is empty
    private func emptyState(message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
    }
}

// MARK: - Preview
#Preview {
    HistoryView(
        questsData: SampleData.scheduledQuests,
        // simulating that the user RSVPed to index [0] and [1]
        rsvpedQuestIDs: [
            SampleData.scheduledQuests[0].id,
            SampleData.scheduledQuests[1].id
        ]
    )
}
